# Sources and verification

Every statement the article and the paper rely on that does not come out of the code, with its
source and how it was checked. Checked on **17 September 2026**. The same method is used in
[pay-transparency-readiness-kit](https://github.com/D0M3N1C0X/pay-transparency-readiness-kit/blob/main/docs/verification.md).

**Status key:** **Verified** - read in the primary source. **Numerically confirmed** - the code
reproduces the published figure. **Bibliographic record checked** - authors, title, journal,
volume, issue and pages confirmed against the publisher or RePEc.

## The Directive

Text: Official Journal L 132, 17 May 2023 ([CELEX 32023L0970](https://eur-lex.europa.eu/eli/dir/2023/970/oj)).

| Statement | Where | Status |
|---|---|---|
| 250+ workers report every year from 7 June 2027; 150-249 every three years from 7 June 2027; 100-149 every three years from 7 June 2031, on the previous calendar year | Art. 9(2)-(4) | Verified |
| A joint pay assessment follows a gap of at least 5% in a category of workers that is neither justified on objective, gender-neutral criteria nor remedied within six months | Art. 10(1) | Verified |
| Workers can request pay information, from any employer | Art. 7 | Verified |
| Pay progression criteria must be accessible to workers | Art. 6 | Verified |
| The Directive applies to public and private employers | Art. 2(1) | Verified |

## Eurostat

| Statement | Source | Status |
|---|---|---|
| The published gap covers enterprises with 10+ employees, NACE sections B to S excluding O, gross hourly earnings including paid overtime and excluding non-regular payments | [Metadata earn_grgpg2](https://ec.europa.eu/eurostat/cache/metadata/en/earn_grgpg2_esms.htm) | Verified |
| The EU gap is "the weighted mean of the gender pay gaps in EU Member States, where the numbers of employees in Member States are weights" | same | Verified, and numerically confirmed: 12.2% published, 12.22% rebuilt (`outputs/eu_aggregate_check.csv`) |
| Years between the four-yearly SES are estimated from national sources with the same coverage | same | Verified |
| Sector cells of SES 2022 rebuild each national 2022 gap | `outputs/decomposition_2022.csv` | Numerically confirmed for all 27 countries, within 0.42 points |
| Size classes in SES 2022 are 1-9, 10-49, 50-249, 250-499, 500-999 and 1,000+; the Directive's 100 and 150 thresholds cannot be separated | dimension `sizeclas` of `earn_ses22_53` | Verified in the data |

Every dataset is stored in `data/raw/` with the API address and the retrieval date.

## Literature

| Reference | Status |
|---|---|
| Oaxaca (1973), *International Economic Review* 14(3): 693-709 | Bibliographic record checked (RePEc) |
| Blinder (1973), *Journal of Human Resources* 8(4): 436-455 | Bibliographic record checked (RePEc) |
| Reimers (1983), *Review of Economics and Statistics* 65(4): 570-579 | Bibliographic record checked (JSTOR, RePEc) |
| Blau and Kahn (2017), *Journal of Economic Literature* 55(3): 789-865 | Bibliographic record checked (AEA) |
| Olivetti and Petrongolo (2008), *Journal of Labor Economics* 26(4): 621-654 | Bibliographic record checked (RePEc); the selection argument cited is the paper's own summary |
| Leythienne and Ronkowski (2018), Eurostat Statistical Working Paper KS-TC-18-003, doi:10.2785/796328 | Bibliographic record checked (EU Publications Office) |

## What this work is not

- **Not an adjusted gap and not a measure of discrimination.** The decomposition uses published
  cell means and controls for nothing but the cell.
- **Not a forecast of what any employer will report.** An employer's categories of workers are far
  narrower than any cell here.
- **Not legal advice.** National transposition decides how the reports are computed.

## Known gaps

- SES 2022 predates the Directive and excludes public administration (section O) and enterprises
  under ten employees.
- Enterprises are statistical units; the Directive's reporting unit is the legal employer.
- Finer decompositions cover only the countries where Eurostat publishes complete cells.
