"""Exporta o consumo de uma sessão local do Codex por execução de skill."""

import argparse
import csv
import json
import re
from pathlib import Path


SKILLS = {
    "arquitetura-analise-negocio", "arquitetura-analise-tecnica",
    "arquitetura-gerar-mapa-testes", "arquitetura-validar-ambiente",
    "arquitetura-executar-teste", "arquitetura-analise-falha",
    "arquitetura-gerar-defeito",
}
FIELDS = (
    "input_tokens", "cached_input_tokens", "cache_write_input_tokens",
    "output_tokens", "reasoning_output_tokens", "total_tokens",
)
COMMAND = re.compile(r"^\s*[/\$]([a-z0-9-]+)(?=\s|$)", re.IGNORECASE)


def usage_fields(usage):
    return {field: usage.get(field) for field in FIELDS}


def aggregate(usages):
    return {
        field: sum(usage[field] for usage in usages)
        if usages and all(usage[field] is not None for usage in usages) else None
        for field in FIELDS
    }


def read_session(path):
    session_id = path.stem
    executions = [{"skill": "outros", "turns": set(), "usage": []}]
    active = executions[0]
    turn_id = None
    turn_owners = {}
    responses = {}
    cumulative = {}
    declared_turns = set()

    with path.open(encoding="utf-8-sig") as source:
        for number, line in enumerate(source, 1):
            if not line.strip():
                continue
            try:
                record = json.loads(line)
            except json.JSONDecodeError as error:
                if not line.endswith("\n"):
                    break  # O aplicativo pode estar gravando a última linha.
                raise ValueError(f"JSON inválido na linha {number}") from error

            payload = record.get("payload") or {}
            kind = (record.get("type"), payload.get("type"))
            if kind[0] == "session_meta":
                session_id = payload.get("id") or session_id
            elif kind == ("event_msg", "task_started"):
                turn_id = payload.get("turn_id")
                if turn_id:
                    declared_turns.add(turn_id)
            elif kind == ("response_item", "message") and payload.get("role") == "user":
                for part in payload.get("content", []):
                    if part.get("type") != "input_text":
                        continue
                    command = COMMAND.match(part.get("text", ""))
                    if command is None:
                        continue
                    name = command[1].lower()
                    if turn_id in turn_owners:
                        break  # Mudanças entram apenas no início do turno.
                    if name in SKILLS:
                        active = {"skill": name, "turns": set(), "usage": []}
                        executions.append(active)
                    elif name == "fim-skill":
                        active = executions[0]
                    break
            elif kind[0] == "token_usage_record":
                usage = payload.get("usage")
                response_id = payload.get("response_id")
                owner_turn = payload.get("turn_id")
                if payload.get("thread_token_usage"):
                    cumulative = payload["thread_token_usage"]
                if response_id and owner_turn and usage and response_id not in responses:
                    owner = turn_owners.setdefault(
                        owner_turn, active if owner_turn == turn_id else executions[0]
                    )
                    owner["turns"].add(owner_turn)
                    responses[response_id] = usage_fields(usage)
                    owner["usage"].append(responses[response_id])
            elif kind == ("event_msg", "token_count"):
                snapshot = (payload.get("info") or {}).get("total_token_usage")
                if snapshot:
                    cumulative = snapshot

    measured = aggregate(list(responses.values()))
    total = usage_fields(cumulative) if cumulative else measured
    difference = None
    if total["total_tokens"] is not None:
        difference = total["total_tokens"] - (measured["total_tokens"] or 0)

    rows = []
    for index, execution in enumerate(executions):
        if index == 0 and not execution["usage"]:
            continue
        rows.append({
            "sessao_id": session_id,
            "tipo": "skill" if index else "outros",
            "execucao": index or None,
            "skill": execution["skill"] if index else None,
            "turnos_com_medicao": len(execution["turns"]),
            **aggregate(execution["usage"]),
        })
    if difference is not None and difference > 0:
        rows.append({
            "sessao_id": session_id, "tipo": "sem_atribuicao",
            **{
                field: total[field] - measured[field]
                if total[field] is not None and measured[field] is not None
                and total[field] >= measured[field] else None
                for field in FIELDS
            },
            "total_tokens": difference,
        })
    rows.append({
        "sessao_id": session_id, "tipo": "sessao",
        "turnos_com_medicao": len(turn_owners), **total,
    })
    return rows, difference, len(declared_turns - turn_owners.keys())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sessao", help="ID exato da sessão ou caminho do rollout JSONL")
    parser.add_argument("--csv", type=Path, help="Arquivo CSV de saída")
    args = parser.parse_args()
    path = Path(args.sessao)
    if not path.is_file():
        if not re.fullmatch(r"[0-9a-fA-F-]{36}", args.sessao):
            parser.error("Informe um arquivo JSONL existente ou o ID da sessão.")
        matches = list((Path.home() / ".codex" / "sessions").rglob(
            f"rollout-*-{args.sessao}.jsonl"
        ))
        if len(matches) != 1:
            parser.error("A sessão não foi localizada de forma única. Informe o caminho do JSONL.")
        path = matches[0]
    if args.csv and args.csv.resolve() == path.resolve():
        parser.error("Escolha um arquivo de saída diferente do log de entrada.")

    try:
        rows, difference, missing_turns = read_session(path)
        if args.csv:
            with args.csv.open("w", encoding="utf-8-sig", newline="") as output:
                writer = csv.DictWriter(output, fieldnames=[
                    "sessao_id", "tipo", "execucao", "skill", "turnos_com_medicao", *FIELDS,
                ])
                writer.writeheader()
                writer.writerows(rows)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Erro: {error}\n")

    for row in rows:
        tokens = row["total_tokens"]
        number = f' #{row["execucao"]}' if row.get("execucao") else ""
        print(f'{row.get("skill") or row["tipo"]}{number}: '
              f'{tokens if tokens is not None else "indisponível"}')
    if difference is not None and difference < 0:
        parser.exit(1, "O total do log ficou abaixo da soma das respostas. Revise o relatório.\n")
    if missing_turns:
        print(f"Turnos sem registro de uso por resposta: {missing_turns}")


if __name__ == "__main__":
    main()
