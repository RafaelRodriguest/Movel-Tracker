#!/usr/bin/env python3
"""Converte a planilha de sites em arquivos .sql prontos para o SQL Editor do Supabase.

Foi assim que os 1481 sites de AM/PA/RR/AP entraram em 2026-08-17. O import
"Import Data from CSV" do Studio casa colunas pelo *nome* do cabeçalho, e as
planilhas da Claro chegam com `UF` maiúsculo, em ISO-8859-1, separadas por `;`,
com vírgula decimal e `status` minúsculo — tratar isso offline sai mais barato
que consertar depois de importado.

Uso:
    python3 csv_to_sql.py ~/Downloads/planilha.csv [diretorio-de-saida]

Gera import_sites_01.sql, _02.sql, ... com ~500 linhas cada (acima disso o editor
do navegador engasga). Cole um de cada vez no SQL Editor e rode.

O `on conflict (site_id) do update` atualiza sites já existentes sem encostar nas
fotos nem nos campos operacionais — eles não aparecem no `update set`.

Detalhes em SKILS.md/import-csv-multi-estado.md.
"""
import csv
import os
import sys

ENCODING = "iso-8859-1"
DELIMITER = ";"
CHUNK = 500
UFS_VALIDAS = {"MA", "PA", "AM", "RR", "AP"}

COLS = (
    "site_id, sigla, nome, endereco, municipio, uf, "
    "tecnico, latitude, longitude, detentora, uc, status"
)

CONFLICT = """on conflict (site_id) do update set
  sigla     = excluded.sigla,
  nome      = excluded.nome,
  endereco  = excluded.endereco,
  municipio = excluded.municipio,
  uf        = excluded.uf,
  tecnico   = excluded.tecnico,
  latitude  = excluded.latitude,
  longitude = excluded.longitude,
  detentora = excluded.detentora,
  uc        = excluded.uc,
  status    = excluded.status;"""


def q(valor):
    """Literal de texto, ou null se vazio."""
    if valor is None:
        return "null"
    valor = valor.strip()
    if not valor:
        return "null"
    return "'" + valor.replace("'", "''") + "'"


def num(valor, site_id, campo):
    """Coordenada: vírgula decimal vira ponto; vazio vira null."""
    if valor is None:
        return "null"
    valor = valor.strip().replace(",", ".")
    if not valor:
        return "null"
    try:
        float(valor)
    except ValueError:
        sys.exit(f"{site_id}: {campo} não é numérico: {valor!r}")
    return valor


def coluna(linha, *nomes):
    """Lê a coluna aceitando variação de caixa no cabeçalho (uf/UF)."""
    for nome in nomes:
        if nome in linha:
            return linha[nome]
    sys.exit(f"coluna ausente no CSV: {nomes[0]}")


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    origem = sys.argv[1]
    destino = sys.argv[2] if len(sys.argv) > 2 else os.getcwd()

    with open(origem, encoding=ENCODING, newline="") as f:
        linhas = list(csv.DictReader(f, delimiter=DELIMITER))

    vistos = set()
    values = []
    for linha in linhas:
        site_id = (coluna(linha, "site_id") or "").strip()
        if not site_id:
            sys.exit("linha sem site_id")
        if site_id in vistos:
            sys.exit(f"site_id duplicado no CSV: {site_id}")
        vistos.add(site_id)

        uf = (coluna(linha, "uf", "UF") or "").strip().upper()
        if uf not in UFS_VALIDAS:
            sys.exit(f"{site_id}: UF inesperada: {uf!r}")

        status = (coluna(linha, "status") or "").strip().capitalize() or "Ativo"

        values.append(
            "  ({}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {})".format(
                q(site_id),
                q(coluna(linha, "sigla")),
                q(coluna(linha, "nome")),
                q(coluna(linha, "endereco")),
                q(coluna(linha, "municipio")),
                q(uf),
                q(coluna(linha, "tecnico")),
                num(coluna(linha, "latitude"), site_id, "latitude"),
                num(coluna(linha, "longitude"), site_id, "longitude"),
                q(coluna(linha, "detentora")),
                q(coluna(linha, "uc")),
                q(status),
            )
        )

    os.makedirs(destino, exist_ok=True)
    partes = [values[i:i + CHUNK] for i in range(0, len(values), CHUNK)]
    for n, parte in enumerate(partes, 1):
        caminho = os.path.join(destino, f"import_sites_{n:02d}.sql")
        with open(caminho, "w", encoding="utf-8") as out:
            out.write(f"-- Parte {n}/{len(partes)} — {len(parte)} sites\n")
            out.write(f"insert into sites ({COLS})\nvalues\n")
            out.write(",\n".join(parte))
            out.write("\n" + CONFLICT + "\n")
        print(f"{caminho}  {len(parte)} linhas  {os.path.getsize(caminho) // 1024} KB")

    print(f"total: {len(values)} sites em {len(partes)} arquivos")


if __name__ == "__main__":
    main()
