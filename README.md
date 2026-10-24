# VQ MACD Waves 7TF

A free MQL4 indicator for MetaTrader 4 that draws the MACD of seven timeframes —
**D1, H4, H1, M30, M15, M5, M1** — as seven waves in one window, and marks the moments
when the small timeframes turn against the big ones (**conflict**).

Published by **[VertQuant](https://www.youtube.com/@VertQuant)** —
honest, statistics-backed testing of trading ideas on YouTube.

## How to read it

| What you see | Meaning |
|---|---|
| Seven waves, top to bottom | D1, H4, H1, M30, M15, M5, M1 — MACD histogram (MACD − signal) of each timeframe |
| **Teal** segment | strict momentum **up**: MACD > 0, MACD above its signal line, MACD rising |
| **Orange** segment | strict momentum **down**: MACD < 0, below its signal line, falling |
| Grey segment | neither (neutral) |
| **Gold dot** | a **conflict** starts: D1 and H4 point the same way, while M15, M5 and M1 all point the other way |
| Small teal mark | a **re-sync** starts: after a conflict (within 240 min), the small timeframes line up with D1/H4 again |
| Labels on the right | each timeframe's current state and histogram value (enable chart shift to see them) |

Only **closed** candles are used: each timeframe updates when its own candle closes
(the D1 wave changes once a day). The signal line is an **EMA(9)** of MACD — the built-in
MACD in MetaTrader uses an SMA, so values differ slightly from it.

Best viewed on **M1–M15** charts. On higher charts, short conflicts between two chart candles are not visible.

## What the test showed (history, not a guarantee)

EUR/USD and gold, one-minute data 2015–2026; rules written down before testing; final test on 2023–2025, opened once.

- **All waves agreeing** gave no edge: the next hour looked like a random moment in the same trend.
- **Conflict** (gold dot): the D1/H4 trend reversed within 4 hours (≥ 2 hourly ranges against it and the
  H4 momentum flipped) in **15.4%** of cases vs **8.6%** at random moments of the same trend.
  In 85 of 100 conflicts there was **no** reversal — treat it as a risk warning, not as a signal.

## Installation

1. Download `MACD_Waves_7TF.mq4` from this repository.
2. Open MetaTrader 4 → File → Open Data Folder.
3. Copy the file into `MQL4/Indicators/`.
4. Restart MetaTrader 4 (or right-click "Indicators" in the Navigator and choose Refresh).
5. Drag the indicator onto an M1–M15 chart. All seven timeframes need history for the symbol.

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `InpFast` / `InpSlow` / `InpSignal` | 12 / 26 / 9 | MACD periods (signal is an EMA) |
| `InpBarsToDraw` | 3000 | chart bars to draw (raise to look further back, e.g. 20000 on M1) |
| `InpHistoryTF` | 3000 | bars of each timeframe used for the averages (raise together with the one above) |
| `InpWarmup` | 300 | oldest bars of each timeframe ignored while the averages warm up |
| `InpResyncMin` | 240 | re-sync window after a conflict, minutes |
| `InpExportCSV` | false | write the states to `MQL4/Files/MACD_Waves_7TF_<symbol>.csv` |
| `InpColUp` / `InpColDn` / `InpColFlat` / `InpColConflict` | teal / orange / grey / gold | colours |
| `InpWidthColor` / `InpWidthFlat` | 4 / 2 | line widths of coloured and neutral segments |

## Disclaimer

This indicator is educational material. It is not trading advice and does not guarantee profit.
Results shown in any accompanying video describe past price behaviour under specific test conditions
and do not guarantee future results. Use at your own risk.

## License

MIT — see [LICENSE](LICENSE). Free to use, modify and redistribute.
