# Design System — Tema Claro & Escuro

> Extraído de dois templates de referência (aura.build) e consolidado para o app (Fase 4).
> ⚠️ As referências são **duas identidades distintas**, não light/dark do mesmo sistema — ver §5 (Reconciliação).
> Implementação alvo: **CSS variables + Tailwind** com classe `.dark`, fontes **Inter** (corpo) + **Bricolage Grotesque** (display).

---

## 1. Tema CLARO — "AI Automation" (editorial/Swiss)

**Cores**
| Token | Valor | Uso |
|---|---|---|
| `--bg` | `#F3F3F1` | fundo da página |
| `--bg-outer` | `stone-300` `#D6D3D1` | moldura externa |
| `--surface` | `gray-200` `#E5E7EB` | cards |
| `--surface-glass` | `white/10` + `backdrop-blur-xl`, borda `white/40` | vidro |
| `--section-dark` | `#08090A` | seções escuras de contraste |
| `--text` | `#0A0A0A` / `gray-900` | texto primário |
| `--text-muted` | `gray-500` | secundário |
| `--text-subtle` | `gray-400` | rótulos/terciário |
| `--accent` | `blue-600` `#2563EB` | acento |
| `--accent-soft` | `blue-400` / `blue-500/20` | realces/tints |
| `--btn` | `#1A1A1A` → hover `black` | botão primário |

**Tipografia (Inter):** H1 `text-7xl→9xl` (112–144px) `font-semibold tracking-tighter leading-[0.85]` · H2 `text-xl` medium ·
Section label `0.65rem uppercase tracking-[0.25em] text-gray-400` · Body `text-base` (16/24) `text-gray-500`.

**Forma & motion:** raio containers `2.5rem`/`2rem`, botões `rounded-full`; sombras suaves; `hover:scale-105`,
`group-hover:scale-[1.02]`, badges com `-rotate-2 hover:rotate-0`, `animate-pulse`.

---

## 2. Tema ESCURO — "Luminous" (AI/glow)

**Cores**
| Token | Valor | Uso |
|---|---|---|
| `--bg` | `#050505` | fundo |
| `--card` | `#0A0A0A` | cartões |
| `--surface` | `neutral-900` `#171717` | superfície |
| `--surface-glass` | `white/[0.02]`–`white/5`, borda `white/10` (`white/5` sutil) | vidro |
| `--text` | `white` | primário |
| `--text-muted` | `neutral-300/400` | secundário/terciário |
| `--text-subtle` | `neutral-500` | mudo |
| `--accent` | `orange-500` `#F97316` / `orange-400` `#FB923C` | acento |
| `--accent-2` | `amber-500` | realce |
| `--accent-tint` | `orange-500/10`, ring `orange-500/20–30` | badges/realces |

**Tipografia (Bricolage Grotesque display + Inter corpo):** H1 `text-5xl→76px` `font-light leading-[1.05] tracking-tight` ·
H2 `48px` · H3 `24px` · Body-lg 18/28 · Body 14/22 · Small 12/16 · Texto gradiente `from-white via-orange-200 to-orange-400`.

**Componentes-chave:**
- **Botão primário**: gradiente `from-yellow-200 via-orange-400 to-orange-500`, texto `#2C1306`, `ring-1 ring-inset ring-white/40`, glow `shadow-[0_0_40px_-5px_rgba(249,115,22,.6)]`, `hover:scale-105`.
- **Botão secundário**: `bg-white text-black`; **terciário**: gradiente laranja; **texto**: `neutral-400 hover:text-white`.
- **Input**: `bg-[#050505] border-white/10 focus-within:border-white/20 rounded-lg` (busca: `bg-black/40 ring-white/10`).
- **Card padrão**: `ring-1 ring-white/10 bg-white/[0.02] hover:bg-white/[0.04]`; **electric**: borda em gradiente + glow laranja.
- **Badge "Live"**: ponto com `animate-ping` laranja; **Trending**: `bg-orange-500/10 text-orange-400 ring-orange-500/20`.
- **Toggle**: trilho `orange-500/20 ring-orange-500/30`, botão `orange-400`, `translate-x-4`.

**Efeitos & motion:** glassmorphism; glow (`shadow-[…rgba(249,115,22,…)]`); fundo `stars` + `grid-bg` (`#ffffff05`, 24px);
borda em gradiente via `--border-gradient` (`::before` com mask); entrada `fadeInUpBlur` (translateY+blur) com `delay-75…700`;
`animate-on-scroll` via IntersectionObserver (threshold 0.2).

---

## 3. Comuns aos dois temas

Inter como base de corpo · ícones **Lucide** · botões **pill** · `hover:scale-105` · escala de espaçamento
`gap 2/4/6/8/12/20/24` (8–96px) · container central (`max-w-[1400px]` claro / `max-w-7xl`=1280px escuro) ·
rótulos de seção em uppercase tracked.

---

## 4. Implementação (alvo)

```css
:root {                      /* CLARO */
  --bg:#F3F3F1; --surface:#E5E7EB; --section-dark:#08090A;
  --text:#0A0A0A; --text-muted:#6B7280; --text-subtle:#9CA3AF;
  --accent:#2563EB; --border:rgba(0,0,0,.08); --radius:1rem; --radius-lg:2rem;
}
.dark {                      /* ESCURO */
  --bg:#050505; --surface:#171717; --card:#0A0A0A;
  --text:#FFFFFF; --text-muted:#A3A3A3; --text-subtle:#737373;
  --accent:#2563EB; --accent-2:#60A5FA; --border:rgba(255,255,255,.10); --radius:.75rem; --radius-lg:2rem;
}
```
- Tailwind: `theme.extend.colors` referenciando as variáveis (`bg: 'var(--bg)'`, `accent: 'var(--accent)'`, …).
- Alternância de tema por classe `.dark` no `<html>`, persistida em `localStorage` e respeitando `prefers-color-scheme`.
- Fontes: **Inter** (corpo nos dois temas) + **Bricolage Grotesque** (títulos **apenas no escuro**); no tema claro os títulos usam **Inter** (semibold, `tracking-tighter`).

---

## 5. Reconciliação (decisões aplicadas)

As referências divergem em marca; decisões tomadas para manter coesão entre claro/escuro:

| Tema | Acento (ref) | Display (mantido) | Vibe |
|---|---|---|---|
| Claro | azul | **Inter** semibold | editorial/flat |
| Escuro | laranja | **Bricolage** light | glow/glass |

- **Acento único** nos dois modos — **azul `#2563EB`** (escolha enterprise/BI). No tema escuro isso **substitui o laranja**: gradientes, glow, badges e toggles passam a usar azul (ex.: botão `from-blue-300 via-blue-500 to-blue-600`; glow `rgba(37,99,235,.6)`; ring `blue-500/30`). *Trocar para laranja depois é um único swap da variável `--accent`.*
- **Display fiel a cada referência**: claro = **Inter** (semibold, `tracking-tighter`); escuro = **Bricolage Grotesque** (light). **Corpo = Inter** nos dois.
- **Intensidade**: superfícies mais calmas nas áreas de dados (configurador, histórico); glow/gradiente reservado a **acentos e CTA**. Login/hero podem usar o efeito completo.

---

## 6. Mapeamento para os componentes do app (Fase 4)

| Componente | Claro | Escuro |
|---|---|---|
| **AppShell / header** | `#F3F3F1` sticky + blur, borda `gray-200/50` | `#050505/80 backdrop-blur border-white/5` |
| **Login** | content card sobre `bg-white/50` | **electric/glass card** + glow |
| **Configurador** (seletores) | cards `gray-200`/`white/50`, pills | cards `ring-white/10 bg-white/[0.02]`, pills |
| **Botão "Gerar"** | primário `#1A1A1A` (ou acento) | gradiente do acento + glow |
| **PlanoView** (streaming) | markdown sobre superfície; badge "Live" com ping no estado *streaming* | idem, badge laranja/acento |
| **Histórico** | lista de cards + badges de status | idem (cards glass) |
| **Status badges** | queued/running/done/error → variantes de badge | idem |
| **Motion** | hover scale, transitions | `fadeInUpBlur` na entrada, hover bg/border/scale |

Estados de status mapeiam para badges: `QUEUED` (neutro), `RUNNING` (acento + ping), `DONE` (verde), `ERROR` (vermelho), `CANCELED` (mudo).
