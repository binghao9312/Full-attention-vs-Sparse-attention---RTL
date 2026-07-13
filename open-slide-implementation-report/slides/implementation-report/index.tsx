import type { Page, SlideMeta } from '@open-slide/core';

import archSvg from './assets/hardware_architecture.svg';
import postsimImg from './assets/Postsim.png';
import presimImg from './assets/Presim.png';
import pythonImg from './assets/python.png';

const palette = {
  bg: '#f7f3ea',
  ink: '#ffffff',
  ink2: '#eef2f4',
  paper: '#ffffff',
  line: '#d8d0c4',
  line2: '#cfc6b8',
  text: '#20242a',
  dark: '#202026',
  soft: '#56606b',
  muted: '#7b746b',
  copper: '#c9783e',
  green: '#39a36a',
  blue: '#4e8dba',
  red: '#d85b55',
};

const font = {
  display: '"Aptos Display", "Microsoft JhengHei", system-ui, sans-serif',
  body: '"Aptos", "Microsoft JhengHei", system-ui, sans-serif',
  mono: '"Aptos Mono", "Cascadia Mono", Consolas, monospace',
};

const page: React.CSSProperties = {
  width: '100%',
  height: '100%',
  background: palette.bg,
  color: palette.text,
  fontFamily: font.body,
  position: 'relative',
  overflow: 'hidden',
  lineHeight: 1.36,
};

const grid: React.CSSProperties = {
  position: 'absolute',
  inset: 0,
  backgroundImage:
    'linear-gradient(rgba(32,36,42,0.045) 1px, transparent 1px), linear-gradient(90deg, rgba(32,36,42,0.045) 1px, transparent 1px)',
  backgroundSize: '96px 96px',
  maskImage: 'radial-gradient(ellipse at center, rgba(0,0,0,0.55), transparent 76%)',
};

const content: React.CSSProperties = {
  position: 'absolute',
  inset: 0,
  padding: '86px 100px 70px',
};

const Kicker = ({ children }: { children: React.ReactNode }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
    <div style={{ width: 48, height: 3, background: palette.copper }} />
    <div
      style={{
        color: palette.soft,
        fontFamily: font.mono,
        fontSize: 20,
        fontWeight: 700,
        letterSpacing: '0.12em',
        textTransform: 'uppercase',
      }}
    >
      {children}
    </div>
  </div>
);

const Title = ({ children, width = 1280 }: { children: React.ReactNode; width?: number }) => (
  <h1
    style={{
      maxWidth: width,
      margin: '26px 0 0',
      fontFamily: font.display,
      fontSize: 67,
      lineHeight: 1.12,
      letterSpacing: '-0.015em',
    }}
  >
    {children}
  </h1>
);

const CompactTitle = ({ children, width = 1400 }: { children: React.ReactNode; width?: number }) => (
  <h1
    style={{
      maxWidth: width,
      margin: '18px 0 0',
      fontFamily: font.display,
      fontSize: 54,
      lineHeight: 1.08,
      letterSpacing: '-0.015em',
    }}
  >
    {children}
  </h1>
);

const Footer = ({ pageNo, source }: { pageNo: string; source?: string }) => (
  <>
    <div
      style={{
        position: 'absolute',
        left: 100,
        bottom: 36,
        color: palette.muted,
        fontFamily: font.mono,
        fontSize: 16,
        lineHeight: 1.45,
      }}
    >
      {source ?? 'Sparse Attention RTL implementation report'}
    </div>
    <div
      style={{
        position: 'absolute',
        right: 100,
        bottom: 34,
        color: palette.muted,
        fontFamily: font.mono,
        fontSize: 18,
      }}
    >
      {pageNo}
    </div>
  </>
);

const Shell = ({
  pageNo,
  kicker,
  title,
  source,
  children,
  titleWidth,
}: {
  pageNo: string;
  kicker: string;
  title: React.ReactNode;
  source?: string;
  children: React.ReactNode;
  titleWidth?: number;
}) => (
  <div style={page}>
    <div style={grid} />
    <div style={content}>
      <Kicker>{kicker}</Kicker>
      <Title width={titleWidth}>{title}</Title>
      {children}
    </div>
    <Footer pageNo={pageNo} source={source} />
  </div>
);

const Card = ({
  children,
  style,
  tone = 'dark',
}: {
  children: React.ReactNode;
  style?: React.CSSProperties;
  tone?: 'dark' | 'paper';
}) => (
  <div
    style={{
      background: tone === 'paper' ? palette.paper : palette.ink,
      border: `1px solid ${tone === 'paper' ? palette.line2 : palette.line}`,
      borderRadius: 8,
      color: tone === 'paper' ? palette.dark : palette.text,
      lineHeight: 1.45,
      letterSpacing: 0,
      ...style,
    }}
  >
    {children}
  </div>
);

const Pill = ({ children, color = palette.copper }: { children: React.ReactNode; color?: string }) => (
  <span
    style={{ display: 'inline-block', padding: '7px 14px', border: `1px solid ${color}66`, borderRadius: 999, color: color, fontFamily: font.mono, fontSize: 20, fontWeight: 700, lineHeight: '1.15', letterSpacing: '1.5px' }}
  >
    {children}
  </span>
);

const Bullet = ({ children, color = palette.green, style }: { children: React.ReactNode; color?: string; style?: React.CSSProperties }) => (
  <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start', fontSize: 28, lineHeight: 1.48, ...style }}>
    <div style={{ width: 13, height: 13, borderRadius: '50%', background: color, marginTop: 14 }} />
    <div>{children}</div>
  </div>
);

const Metric = ({
  value,
  label,
  note,
}: {
  value: string;
  label: string;
  note: string;
}) => (
  <Card style={{ padding: '28px 30px', minHeight: 134 }}>
    <div style={{ fontFamily: font.display, fontSize: 48, fontWeight: 800 }}>{value}</div>
    <div style={{ marginTop: 8, color: palette.copper, fontFamily: font.mono, fontSize: 18, fontWeight: 700 }}>
      {label}
    </div>
    <div style={{ marginTop: 12, color: palette.soft, fontSize: 18, lineHeight: 1.45 }}>{note}</div>
  </Card>
);

const PipelineStage = ({
  index,
  title,
  detail,
  accent = palette.copper,
}: {
  index: string;
  title: string;
  detail: string;
  accent?: string;
}) => (
  <Card style={{ width: 286, minHeight: 238, padding: '28px 26px', borderTop: `7px solid ${accent}` }}>
    <div style={{ color: accent, fontFamily: font.mono, fontSize: 20, fontWeight: 900 }}>{index}</div>
    <div style={{ marginTop: 18, fontFamily: font.display, fontSize: 34, fontWeight: 800, lineHeight: 1.12 }}>{title}</div>
    <div style={{ marginTop: 18, color: palette.soft, fontSize: 21, lineHeight: 1.4 }}>{detail}</div>
  </Card>
);

const ImageFrame = ({
  src,
  alt,
  style,
  fit = 'contain',
}: {
  src: string;
  alt: string;
  style?: React.CSSProperties;
  fit?: 'contain' | 'cover';
}) => (
  <Card tone="paper" style={{ padding: 18, ...style }}>
    <img
      src={src}
      alt={alt}
      style={{ display: 'block', width: '100%', height: '100%', objectFit: fit }}
    />
  </Card>
);

const comparisonRows = [
  { mode: 'dense', pairs: 16384, mac: 65536, color: palette.blue },
  { mode: 'sliding', pairs: 512, mac: 2048, color: palette.copper },
  { mode: 'dilated', pairs: 256, mac: 1024, color: palette.green },
  { mode: 'butterfly', pairs: 896, mac: 3584, color: palette.red },
];

const chartMetrics = [
  { key: 'mac', label: 'MAC count', max: 65536, format: (value: number) => value.toLocaleString() },
  { key: 'cycles', label: 'cycle count', max: 16384, format: (value: number) => value.toLocaleString() },
  { key: 'time', label: 'est. time', max: 163.84, format: (value: number) => `${value.toFixed(2)}us` },
] as const;

const softwareRuntimeRows = [
  { seq: '16', full: 7.989, sliding: 4.012, dilated: 3.192, butterfly: 2.991 },
  { seq: '32', full: 25.613, sliding: 7.675, dilated: 6.292, butterfly: 7.0 },
  { seq: '64', full: 127.951, sliding: 16.102, dilated: 12.733, butterfly: 16.385 },
  { seq: '128', full: 508.449, sliding: 34.593, dilated: 26.21, butterfly: 36.384 },
];

const postSimRuntimeRows = [
  { seq: '16', full: 2.56, sliding: 0.64, dilated: 0.32, butterfly: 0.64 },
  { seq: '32', full: 10.24, sliding: 1.28, dilated: 0.64, butterfly: 1.6 },
  { seq: '64', full: 40.96, sliding: 2.56, dilated: 1.28, butterfly: 3.84 },
  { seq: '128', full: 163.84, sliding: 5.12, dilated: 2.56, butterfly: 8.96 },
];

const runtimeSeries = [
  { key: 'full', label: 'full', color: palette.blue },
  { key: 'sliding', label: 'sliding', color: palette.copper },
  { key: 'dilated', label: 'dilated', color: palette.green },
  { key: 'butterfly', label: 'butterfly', color: palette.red },
] as const;

const ResultComparisonPanel = ({ title }: { title: string }) => (
  <Card tone="paper" style={{ padding: '22px 24px' }}>
    <div style={{ fontFamily: font.display, fontSize: 30, fontWeight: 800, lineHeight: 1.08 }}>{title}</div>
    <div style={{ marginTop: 8, color: palette.soft, fontFamily: font.mono, fontSize: 15, lineHeight: 1.35 }}>
      seq_len=128, FEATURE_DIM=4, 10 ns clock assumption
    </div>
    <div style={{ marginTop: 18, borderLeft: `1px solid ${palette.line2}`, borderBottom: `1px solid ${palette.line2}`, padding: '0 0 10px 12px' }}>
      <div style={{ height: 250, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 22, alignItems: 'end' }}>
        {chartMetrics.map((metric) => {
          return (
            <div key={metric.key} style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
              <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'center', gap: 8, height: 210 }}>
                {comparisonRows.map((row) => {
                  const values = {
                    mac: row.mac,
                    cycles: row.pairs,
                    time: (row.pairs * 10) / 1000,
                  };
                  const value = values[metric.key];
                  const height = Math.max(8, (value / metric.max) * 204);
                  return (
                    <div
                      key={row.mode}
                      title={`${metric.label}: ${row.mode}`}
                      style={{
                        width: 18,
                        height,
                        background: row.color,
                        borderRadius: '3px 3px 0 0',
                      }}
                    />
                  );
                })}
              </div>
              <div style={{ marginTop: 10, textAlign: 'center', fontFamily: font.mono, fontSize: 16, fontWeight: 800 }}>
                {metric.label}
              </div>
            </div>
          );
        })}
      </div>
    </div>
    <div style={{ marginTop: 12, display: 'flex', gap: 16, justifyContent: 'center', flexWrap: 'wrap' }}>
      {comparisonRows.map((row) => (
        <div key={row.mode} style={{ display: 'flex', alignItems: 'center', gap: 7, fontFamily: font.mono, fontSize: 14, color: palette.soft }}>
          <div style={{ width: 12, height: 12, background: row.color }} />
          {row.mode}
        </div>
      ))}
    </div>
    <div
      style={{
        marginTop: 14,
        border: `1px solid ${palette.line2}`,
        borderRadius: 6,
        overflow: 'hidden',
        fontFamily: font.mono,
        fontSize: 13,
        lineHeight: 1.25,
      }}
    >
      <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr 1fr 1fr 1fr', background: '#eee7dc', fontWeight: 800 }}>
        {['mode', 'MAC', 'cycle', 'time', 'reduct.'].map((cell) => (
          <div key={cell} style={{ padding: '8px 7px', borderRight: `1px solid ${palette.line2}` }}>
            {cell}
          </div>
        ))}
      </div>
      {comparisonRows.map((row) => {
        const timeUs = (row.pairs * 10) / 1000;
        const reduction = 100 - (row.mac / 65536) * 100;
        return (
          <div key={row.mode} style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr 1fr 1fr 1fr', background: palette.paper }}>
            {[row.mode, row.mac.toLocaleString(), row.pairs.toLocaleString(), `${timeUs.toFixed(2)}us`, row.mode === 'dense' ? '-' : `${reduction.toFixed(1)}%`].map((cell, i) => (
              <div
                key={`${row.mode}-${i}`}
                style={{
                  padding: '7px 7px',
                  borderTop: `1px solid ${palette.line2}`,
                  borderRight: `1px solid ${palette.line2}`,
                  color: i === 0 ? palette.text : palette.soft,
                  fontWeight: i === 0 ? 800 : 600,
                  textAlign: i === 0 ? 'left' : 'right',
                }}
              >
                {cell}
              </div>
            ))}
          </div>
        );
      })}
    </div>
  </Card>
);

const SoftwareHardwareComparison: Page = () => (
  <Shell
    pageNo="14"
    kicker="Experiment Result / Runtime"
    title="Runtime is compared by input length: Python software time and post-sim estimated time."
    titleWidth={1360}
  >
    <div style={{ marginTop: 38, display: 'grid', gridTemplateColumns: '1.05fr 0.95fr', gap: 30, alignItems: 'start' }}>
      <Card tone="paper" style={{ padding: '34px 38px' }}>
        <div style={{ fontFamily: font.display, fontSize: 34, fontWeight: 800 }}>Runtime by input length</div>
        <div style={{ marginTop: 8, color: palette.soft, fontFamily: font.mono, fontSize: 16 }}>
          solid = Python runtime_us, translucent = post-sim cycles x 10ns
        </div>
        <div style={{ marginTop: 34, borderLeft: `1px solid ${palette.line2}`, borderBottom: `1px solid ${palette.line2}`, padding: '0 0 12px 18px' }}>
          <div style={{ height: 360, display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 26, alignItems: 'end' }}>
            {softwareRuntimeRows.map((row, rowIndex) => {
              const postRow = postSimRuntimeRows[rowIndex];
              return (
              <div key={row.seq} style={{ height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'flex-end' }}>
                <div style={{ height: 304, display: 'flex', alignItems: 'flex-end', justifyContent: 'center', gap: 8 }}>
                  {runtimeSeries.map((series) => (
                    <div key={series.key} style={{ display: 'flex', alignItems: 'flex-end', gap: 2 }}>
                      <div
                        title={`software ${series.label}: ${row[series.key]}us`}
                        style={{
                          width: 10,
                          height: Math.max(8, (row[series.key] / 508.449) * 292),
                          background: series.color,
                          borderRadius: '3px 3px 0 0',
                        }}
                      />
                    <div
                      title={`post-sim ${series.label}: ${postRow[series.key]}us`}
                      style={{
                        width: 10,
                        height: Math.max(8, (postRow[series.key] / 508.449) * 292),
                        background: series.color,
                        opacity: 0.45,
                        borderRadius: '4px 4px 0 0',
                      }}
                    />
                    </div>
                  ))}
                </div>
                <div style={{ marginTop: 14, textAlign: 'center', fontFamily: font.mono, fontSize: 20, fontWeight: 800, lineHeight: 1.15 }}>
                  seq {row.seq}
                </div>
                <div style={{ marginTop: 6, textAlign: 'center', color: palette.soft, fontFamily: font.mono, fontSize: 16 }}>
                  full {row.full.toFixed(1)}us
                </div>
              </div>
              );
            })}
          </div>
        </div>
        <div style={{ marginTop: 16, display: 'flex', gap: 20, justifyContent: 'center', flexWrap: 'wrap' }}>
          {runtimeSeries.map((series) => (
            <div key={series.key} style={{ display: 'flex', alignItems: 'center', gap: 7, color: palette.soft, fontFamily: font.mono, fontSize: 16 }}>
              <div style={{ width: 15, height: 15, background: series.color }} />
              {series.label}
            </div>
          ))}
          <div style={{ display: 'flex', alignItems: 'center', gap: 7, color: palette.soft, fontFamily: font.mono, fontSize: 16 }}>
            <div style={{ width: 15, height: 15, background: palette.text }} />
            software
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 7, color: palette.soft, fontFamily: font.mono, fontSize: 16 }}>
            <div style={{ width: 15, height: 15, background: palette.text, opacity: 0.45 }} />
            post-sim
          </div>
        </div>
      </Card>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
        <Card style={{ padding: '24px 28px' }}>
          <div style={{ fontFamily: font.display, fontSize: 32, fontWeight: 800 }}>What this page shows</div>
          <div style={{ marginTop: 14, color: palette.soft, fontSize: 23, lineHeight: 1.42 }}>
            Python runtime is measured in software. Post-sim time is estimated from RTL counters, using `cycle x 10ns`, so the two bars show different execution paths on the same input sizes.
          </div>
        </Card>
        <Card tone="paper" style={{ padding: '18px 18px', overflow: 'hidden' }}>
          <div style={{ color: palette.soft, fontFamily: font.mono, fontSize: 13, fontWeight: 800, marginBottom: 8 }}>
            runtime_us
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '38px 46px repeat(4, minmax(0, 1fr))', background: '#eee7dc', fontFamily: font.mono, fontSize: 12, fontWeight: 800 }}>
            {['seq', 'src', 'full', 'slid', 'dil', 'butt'].map((cell) => (
              <div key={cell} style={{ padding: '8px 6px', borderRight: `1px solid ${palette.line2}`, whiteSpace: 'nowrap', overflow: 'hidden' }}>{cell}</div>
            ))}
          </div>
          {softwareRuntimeRows.flatMap((row, rowIndex) => [
            { seq: row.seq, src: 'SW', full: row.full, sliding: row.sliding, dilated: row.dilated, butterfly: row.butterfly },
            { seq: '', src: 'Post', ...postSimRuntimeRows[rowIndex] },
          ]).map((row, idx) => (
            <div key={`${row.seq}-${row.src}-${idx}`} style={{ display: 'grid', gridTemplateColumns: '38px 46px repeat(4, minmax(0, 1fr))', fontFamily: font.mono, fontSize: 12 }}>
              {[row.seq, row.src, row.full.toFixed(2), row.sliding.toFixed(2), row.dilated.toFixed(2), row.butterfly.toFixed(2)].map((cell, i) => (
                <div
                  key={`${row.seq}-${row.src}-${i}`}
                  style={{
                    padding: '7px 6px',
                    borderTop: `1px solid ${palette.line2}`,
                    borderRight: `1px solid ${palette.line2}`,
                    color: i === 0 ? palette.text : palette.soft,
                    fontWeight: i <= 1 ? 800 : 600,
                    textAlign: i <= 1 ? 'left' : 'right',
                    whiteSpace: 'nowrap',
                    overflow: 'hidden',
                  }}
                >
                  {cell}
                </div>
              ))}
            </div>
          ))}
        </Card>
      </div>
    </div>
  </Shell>
);

const Cover: Page = () => (
  <div style={page}>
    <div style={grid} />
    <div
      style={{
        position: 'absolute',
        inset: 0,
        padding: '118px 118px 90px',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
      }}
    >
      <div>
        <Kicker>Post-Implementation Presentation</Kicker>
        <h1
          style={{
            margin: '64px 0 0',
            width: 1220,
            fontFamily: font.display,
            fontSize: 104,
            lineHeight: 1.03,
            letterSpacing: '-0.025em',
          }}
        >
          Sparse Attention RTL:
          <br />
          from sparse pairs to complete context output.
        </h1>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 26 }}>
        <Metric value="RTL" label="IMPLEMENTED" note="QK + fixed-point softmax + weighted-V" />
        <Metric value="Q8.8" label="OUTPUT" note="query, feature, and context value" />
        <Metric value="RERUN" label="NEXT VERIFICATION" note="VCS, T18 synthesis, and post-sim" />
        <Metric value="98.4%" label="BEST REDUCTION" note="seq_len=128 dilated MAC reduction" />
      </div>
    </div>
    <Footer pageNo="01" />
  </div>
);

const PreReview1: Page = () => (
  <Shell
    pageNo="02"
    kicker="Before Implementation / Motivation"
    title="We started from the self-attention bottleneck: full attention grows as N x N."
  >
    <div style={{ marginTop: 78, display: 'grid', gridTemplateColumns: '1.05fr 0.95fr', gap: 56 }}>
      <Card style={{ padding: 44 }}>
        <div style={{ fontFamily: font.display, fontSize: 52, fontWeight: 800 }}>Full attention</div>
        <div style={{ marginTop: 28, display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12 }}>
          {Array.from({ length: 16 }).map((_, i) => (
            <div
              key={i}
              style={{
                height: 74,
                borderRadius: 6,
                background: i % 5 === 0 ? palette.blue : '#e3e8ee',
                border: `1px solid ${palette.line}`,
              }}
            />
          ))}
        </div>
        <div style={{ marginTop: 28, color: palette.soft, fontSize: 26, lineHeight: 1.45 }}>
          Every query token attends to every key token. Pair count = <b>N²</b>.
        </div>
      </Card>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 28 }}>
        <Bullet>Longer sequence length quickly dominates compute and memory movement.</Bullet>
        <Bullet>Sparse attention keeps the useful connectivity but skips many token pairs.</Bullet>
        <Bullet>Hardware target: generate only valid pairs, then count and compute those pairs deterministically.</Bullet>
      </div>
    </div>
  </Shell>
);

const PreReview2: Page = () => (
  <Shell
    pageNo="03"
    kicker="Before Implementation / Pattern Details"
    title="The small design details were pattern phase, line-buffer reuse, and pair-stream accounting."
  >
    <div style={{ marginTop: 72, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 30 }}>
      {[
        ['Pattern controller', 'mode[2:0] selects sliding, dilated, sliding_global, or butterfly traversal.'],
        ['LineBuffer reuse', 'buffer_phase and buffer_select map valid K/V rows into block, global, row-global, or butterfly banks.'],
        ['Stats path', 'pair_valid drives pair_count, cycle_count, and mac_count += FEATURE_DIM.'],
      ].map(([head, body]) => (
        <Card key={head} style={{ padding: 38, minHeight: 334 }}>
          <Pill>{head}</Pill>
          <div style={{ marginTop: 34, fontSize: 29, lineHeight: 1.48 }}>{body}</div>
        </Card>
      ))}
    </div>
    <Card style={{ marginTop: 34, padding: '28px 36px', display: 'flex', gap: 30, alignItems: 'center' }}>
      <div style={{ color: palette.copper, fontFamily: font.mono, fontSize: 22, fontWeight: 800 }}>KEY POINT</div>
      <div style={{ fontSize: 27, color: palette.soft, lineHeight: 1.45 }}>
        Sparse pair generation now feeds a full attention output path; projection, residual, normalization, and MLP remain outside this accelerator block.
      </div>
    </Card>
  </Shell>
);

const PreReview3: Page = () => (
  <Shell
    pageNo="04"
    kicker="Before Implementation / Expected Patterns"
    title="The expected sparse patterns were fixed before RTL, making correctness measurable."
  >
    <div style={{ marginTop: 64, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 36 }}>
      <Card tone="paper" style={{ padding: 36 }}>
        <div style={{ fontFamily: font.display, fontSize: 44, fontWeight: 800 }}>Patterns under test</div>
        {[
          ['full', 'all token pairs'],
          ['sliding', '4-token local block'],
          ['dilated', 'every 2nd key inside local block'],
          ['sliding_global', 'local block plus global token'],
          ['butterfly', 'structured XOR stride pairs'],
        ].map(([mode, desc]) => (
          <div key={mode} style={{ display: 'grid', gridTemplateColumns: '230px 1fr', gap: 20, marginTop: 26 }}>
            <div style={{ fontFamily: font.mono, fontSize: 24, fontWeight: 800, color: palette.copper }}>{mode}</div>
            <div style={{ fontSize: 23, lineHeight: 1.45 }}>{desc}</div>
          </div>
        ))}
      </Card>
      <Card style={{ padding: 42 }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 24 }}>
          <Metric value="16-128" label="SEQ_LEN" note="four sequence blocks" />
          <Metric value="4" label="WINDOW_SIZE" note="local block width" />
          <Metric value="2" label="DILATION" note="dilated local step" />
          <Metric value="0" label="GLOBAL_INDEX" note="global token index" />
        </div>
      </Card>
    </div>
  </Shell>
);

const ImplementationScope: Page = () => (
  <div style={page}>
    <div style={grid} />
    <div style={{ ...content, padding: '62px 92px 58px' }}>
      <Kicker>Implementation Scope</Kicker>
      <CompactTitle width={1420}>
        RTL now has a concrete sparse attention core and verification path.
      </CompactTitle>
      <div style={{ marginTop: 40, display: 'grid', gridTemplateColumns: '1.18fr 0.82fr', gap: 34 }}>
        <Card style={{ padding: '26px 34px' }}>
          {[
            ['sparse_attention_core.v', 'top wrapper: QK, softmax, and weighted-V pipeline'],
            ['qk_pair_streamer.v', 'pattern controller + line buffers'],
            ['pattern_controller.v', 'q_idx, k_idx, pair_valid, buffer_phase'],
            ['KV_LBV2.v', 'parameterized K/V line-buffer shift storage'],
            ['qk_dot_accumulator.v', 'FEATURE_DIM product lanes + score sum'],
            ['sparse_softmax_sv.v', 'max subtraction, exp LUT, normalization, and V accumulation'],
            ['stats_counter.v', 'pair, cycle, and MAC counters'],
          ].map(([file, role]) => (
            <div
              key={file}
              style={{
                display: 'grid',
                gridTemplateColumns: '350px 1fr',
                gap: 24,
                padding: '13px 0',
                borderBottom: file === 'stats_counter.v' ? 'none' : `1px solid ${palette.line}`,
              }}
            >
              <div style={{ fontFamily: font.mono, fontSize: 21, color: palette.copper, fontWeight: 800 }}>{file}</div>
              <div style={{ fontSize: 21, color: palette.soft, lineHeight: 1.42 }}>{role}</div>
            </div>
          ))}
        </Card>
        <Card style={{ padding: 34, display: 'flex', flexDirection: 'column', gap: 24 }}>
          {[
            ['Input contract', '`start`, `cfg_seq_len`, `mode`'],
            ['Debug visibility', 'pair index, buffer signals, counters'],
            ['Result path', 'Q8.8 context output with valid/ready backpressure'],
            ['Evidence', 'golden checks cover QK scores and final context values'],
          ].map(([head, body]) => (
            <div key={head} style={{ display: 'flex', gap: 18, alignItems: 'flex-start' }}>
              <div style={{ width: 12, height: 12, borderRadius: '50%', background: palette.green, marginTop: 12 }} />
              <div>
                <div style={{ fontFamily: font.mono, fontSize: 20, color: palette.copper, fontWeight: 800 }}>{head}</div>
                <div style={{ marginTop: 8, fontSize: 23, lineHeight: 1.45, color: palette.soft }}>{body}</div>
              </div>
            </div>
          ))}
        </Card>
      </div>
    </div>
    <Footer pageNo="05" />
  </div>
);

const Architecture: Page = () => (
  <div style={page}>
    <div style={grid} />
    <div style={{ ...content, padding: '54px 76px 52px' }}>
      <Kicker>Hardware Architecture</Kicker>
      <CompactTitle width={1420}>
        Top-level now reaches the final context vector, not only the QK score.
      </CompactTitle>
      <ImageFrame
        src={archSvg}
        alt="Sparse attention hardware architecture"
        style={{ marginTop: 24, height: 766, padding: 12 }}
      />
    </div>
    <Footer pageNo="06" source="Source: generated from RTL/Rtl/*.v" />
  </div>
);

const FullAttentionPath: Page = () => (
  <div style={page}>
    <div style={grid} />
    <div style={{ ...content, padding: '62px 92px 58px' }}>
      <Kicker>Complete Attention Path</Kicker>
      <CompactTitle width={1500}>Softmax 後面的 weighted-V 與 context 輸出已接回主資料路徑。</CompactTitle>
      <div style={{ marginTop: 54, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <PipelineStage index="01" title="Sparse QK" detail="只計算 pattern 選到的 q-k pair" accent={palette.blue} />
        <div style={{ fontSize: 46, color: palette.muted }}>→</div>
        <PipelineStage index="02" title="Scale + max" detail="除以 √d，並以 row max 防止 overflow" />
        <div style={{ fontSize: 46, color: palette.muted }}>→</div>
        <PipelineStage index="03" title="Softmax" detail="Q0.16 exp LUT 與 row normalization" accent={palette.green} />
        <div style={{ fontSize: 46, color: palette.muted }}>→</div>
        <PipelineStage index="04" title="Weight × V" detail="逐 feature 累加 sparse weighted value" accent={palette.red} />
        <div style={{ fontSize: 46, color: palette.muted }}>→</div>
        <PipelineStage index="05" title="Context" detail="輸出 q_idx、feature_idx、Q8.8 value" accent={palette.green} />
      </div>
      <Card style={{ marginTop: 44, padding: '26px 34px', display: 'grid', gridTemplateColumns: '240px 1fr', gap: 26, alignItems: 'center' }}>
        <Pill color={palette.green}>Completion signal</Pill>
        <div style={{ fontSize: 25, color: palette.soft, lineHeight: 1.45 }}>
          `done` 現在等待最後一筆 context 被接收；FIFO full 時只停住 context，不遺失或重算結果。
        </div>
      </Card>
    </div>
    <Footer pageNo="07" source="Source: RTL/Rtl/sparse_softmax_sv.v + sparse_attention_core.v" />
  </div>
);

const SoftmaxAndSV: Page = () => (
  <Shell pageNo="08" kicker="Fixed-point Implementation" title="數值格式與輸出介面已定義，剩下的是面積與時序最佳化。" titleWidth={1460}>
    <div style={{ marginTop: 54, display: 'grid', gridTemplateColumns: '0.92fr 1.08fr', gap: 38 }}>
      <Card tone="paper" style={{ padding: 42, minHeight: 548 }}>
        <Pill>Stable softmax</Pill>
        <div style={{ marginTop: 42, fontFamily: font.mono, fontSize: 30, fontWeight: 800, lineHeight: 1.65 }}>
          Δ = (row_max − score) &gt;&gt; 1
          <br />
          w = exp_lut(Δ)
          <br />
          context = Σ(w × V) / Σw
        </div>
        <div style={{ marginTop: 38, color: palette.soft, fontSize: 24, lineHeight: 1.5 }}>
          預設 `FEATURE_DIM=4`，右移一位對應 `1/√4`；大於 LUT 範圍的權重視為固定點 underflow。
        </div>
      </Card>
      <Card style={{ padding: 42, minHeight: 548 }}>
        <div style={{ fontFamily: font.display, fontSize: 43, fontWeight: 800 }}>輸出與驗證契約</div>
        <div style={{ marginTop: 34, display: 'flex', flexDirection: 'column', gap: 24 }}>
          <Bullet>每個 query 固定輸出 4 個 feature。</Bullet>
          <Bullet>`context_value` 採 Q8.8，保留加權平均小數。</Bullet>
          <Bullet>Pre-sim golden model 逐筆核對 q、feature、value。</Bullet>
          <Bullet color={palette.copper}>128×128×32 score buffer 必須映射 SRAM。</Bullet>
          <Bullet color={palette.copper}>除法器仍需 synthesis 後決定 pipeline 或替代架構。</Bullet>
        </div>
      </Card>
    </div>
  </Shell>
);

const ExperimentPlan: Page = () => (
  <Shell
    pageNo="09"
    kicker="Experiment Design"
    title="The experiment asks one question: does RTL preserve the software-defined sparse workload?"
  >
    <div style={{ marginTop: 78, display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 24 }}>
      {[
        ['1', 'Python golden', 'expected QK scores and Q8.8 context values'],
        ['2', 'RTL pre-sim', 'rerun the completed source pipeline'],
        ['3', 'Synthesis', 'map score SRAM and close divider timing'],
        ['4', 'Post-sim', 'regenerate and verify the new netlist'],
      ].map(([num, head, body], i) => (
        <Card key={head} style={{ padding: 34, minHeight: 338 }}>
          <div style={{ color: i === 3 ? palette.green : palette.copper, fontFamily: font.mono, fontSize: 46, fontWeight: 900 }}>
            {num}
          </div>
          <div style={{ marginTop: 26, fontFamily: font.display, fontSize: 38, fontWeight: 800 }}>{head}</div>
          <div style={{ marginTop: 22, fontSize: 24, lineHeight: 1.48, color: palette.soft }}>{body}</div>
        </Card>
      ))}
    </div>
    <div style={{ marginTop: 48, display: 'flex', gap: 20, alignItems: 'center' }}>
      <Pill color={palette.green}>PASS condition</Pill>
      <div style={{ fontSize: 29, color: palette.soft }}>
        Every sparse QK score and every q / feature / context value matches the fixed-point golden model.
      </div>
    </div>
  </Shell>
);

const Workload: Page = () => (
  <Shell
    pageNo="10"
    kicker="Experiment Workload"
    title="The same fixed workload is reused across software, pre-sim, and post-sim."
  >
    <div style={{ marginTop: 70, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 40 }}>
      <Card tone="paper" style={{ padding: 42 }}>
        <div style={{ fontFamily: font.display, fontSize: 46, fontWeight: 800 }}>Expected pair count, seq_len=128</div>
        {[
          ['full', 16384, 1],
          ['sliding', 512, 0.03125],
          ['dilated', 256, 0.015625],
          ['sliding_global', 760, 0.04639],
          ['butterfly', 896, 0.05469],
        ].map(([mode, count, ratio]) => (
          <div key={String(mode)} style={{ marginTop: 27 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontFamily: font.mono, fontSize: 23, fontWeight: 800 }}>
              <span>{mode}</span>
              <span>{count.toLocaleString()}</span>
            </div>
            <div style={{ height: 17, marginTop: 10, background: '#ded5c8', borderRadius: 3 }}>
              <div style={{ width: `${Math.max(2, Number(ratio) * 100)}%`, height: '100%', background: mode === 'full' ? palette.blue : palette.copper }} />
            </div>
          </div>
        ))}
      </Card>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 26 }}>
        <Metric value="65,536" label="FULL MACS" note="seq_len=128 baseline" />
        <Metric value="2,048" label="SLIDING MACS" note="96.875% reduction" />
        <Metric value="1,024" label="DILATED MACS" note="98.4375% reduction" />
        <Metric value="3,584" label="BUTTERFLY MACS" note="94.5312% reduction" />
      </div>
    </div>
  </Shell>
);

const PythonResult: Page = () => (
  <Shell pageNo="11" kicker="Experiment Result / Python" title="The existing QK golden baseline is extended to check every final context value.">
    <div style={{ marginTop: 58, display: 'grid', gridTemplateColumns: '420px 1fr', gap: 44 }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
        <Metric value="20" label="VISIBLE CASES" note="4 sequence lengths x 5 modes" />
        <Metric value="checksum" label="DETERMINISTIC QK" note="not only loop counting" />
        <Card style={{ padding: 30, fontSize: 25, lineHeight: 1.5, color: palette.soft }}>
          Existing screenshot: QK baseline. The updated TB also computes Q8.8 Softmax×V results.
        </Card>
      </div>
      <ImageFrame src={pythonImg} alt="Python golden reference output" style={{ height: 640 }} />
    </div>
  </Shell>
);

const PresimResult: Page = () => (
  <Shell
    pageNo="12"
    kicker="Experiment Result / Pre-sim"
    title="Completed path: rerun VCS pre-sim."
    titleWidth={1320}
  >
    <div style={{ marginTop: 30, display: 'grid', gridTemplateColumns: '760px 1fr', gap: 34, alignItems: 'start' }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
        <ImageFrame src={presimImg} alt="Pre-simulation output" style={{ height: 470 }} />
        <Card style={{ padding: '22px 26px', fontSize: 23, lineHeight: 1.42, color: palette.soft }}>
          Historical baseline: visible rows are `PASS`. The source TB now adds per-context checks for the completed pipeline.
        </Card>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
        <ResultComparisonPanel title="Pre-sim: compute reduction" />
        <Card style={{ padding: '22px 26px' }}>
          <div style={{ fontFamily: font.display, fontSize: 30, fontWeight: 800 }}>What changed</div>
          <div style={{ marginTop: 12, color: palette.soft, fontSize: 23, lineHeight: 1.42 }}>
            The RTL does not sweep the full Q-K matrix. Sparse pair count directly lowers cycles, MACs, and estimated compute time.
          </div>
        </Card>
      </div>
    </div>
  </Shell>
);

const PostsimResult: Page = () => (
  <Shell
    pageNo="13"
    kicker="Experiment Result / Post-sim"
    title="Current post-sim is QK-only; regenerate it after synthesis."
    titleWidth={1280}
  >
    <div style={{ marginTop: 30, display: 'grid', gridTemplateColumns: '760px 1fr', gap: 34, alignItems: 'start' }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
        <ImageFrame src={postsimImg} alt="Post-simulation output" style={{ height: 470 }} />
        <Card style={{ padding: '22px 26px', fontSize: 23, lineHeight: 1.42, color: palette.soft }}>
          Historical netlist result: QK counters and reduction pass. It does not yet prove the new Softmax×V hardware.
        </Card>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
        <ResultComparisonPanel title="Historical QK post-sim baseline" />
        <Card style={{ padding: '22px 26px', display: 'grid', gridTemplateColumns: '150px 1fr', gap: 22, alignItems: 'center' }}>
          <div style={{ fontFamily: font.display, fontSize: 34, fontWeight: 800, color: palette.green }}>BASELINE</div>
          <div style={{ color: palette.soft, fontSize: 23, lineHeight: 1.42 }}>
            QK gate-level behavior passed before the new Softmax×V path; regenerate this evidence after resynthesis.
          </div>
        </Card>
      </div>
    </div>
  </Shell>
);

const ReductionSummary: Page = () => (
  <Shell
    pageNo="15"
    kicker="Experiment Result / Summary"
    title="At seq_len=128, sparse modes reduce MAC work by 94.5% to 98.4%."
  >
    <div style={{ marginTop: 74, display: 'grid', gridTemplateColumns: '1.25fr 0.75fr', gap: 42 }}>
      <Card tone="paper" style={{ padding: 46 }}>
        {[
          ['sliding', 96.875, '2,048 MACs'],
          ['dilated', 98.4375, '1,024 MACs'],
          ['sliding_global', 95.3613, '3,040 MACs'],
          ['butterfly', 94.5312, '3,584 MACs'],
        ].map(([mode, pct, mac]) => (
          <div key={String(mode)} style={{ marginTop: 34 }}>
            <div style={{ display: 'grid', gridTemplateColumns: '260px 1fr 130px', gap: 24, alignItems: 'center' }}>
              <div style={{ fontFamily: font.mono, fontSize: 25, fontWeight: 800 }}>{mode}</div>
              <div style={{ height: 22, background: '#ded5c8', borderRadius: 3, letterSpacing: '-0.1px' }}>
                <div
                  style={{
                    width: `${Number(pct)}%`,
                    height: '100%',
                    background: mode === 'dilated' ? palette.green : palette.copper,
                  }}
                />
              </div>
              <div style={{ textAlign: 'right', fontFamily: font.mono, fontSize: 24, fontWeight: 800 }}>
                {Number(pct).toFixed(2)}%
              </div>
            </div>
            <div style={{ marginLeft: 284, marginTop: 9, color: '#625b52', fontFamily: font.mono, fontSize: 17 }}>{mac}</div>
          </div>
        ))}
      </Card>
      <Card style={{ padding: 40 }}>
        <Pill color={palette.green}>QK claim supported</Pill>
        <div style={{ marginTop: 34, display: 'flex', flexDirection: 'column', gap: 26 }}>
          <Bullet style={{ fontSize: '29px' }}>Software expectation exists.</Bullet>
          <Bullet>Existing RTL pre-sim matches it.</Bullet>
          <Bullet>Existing QK post-sim still passes.</Bullet>
          <Bullet>MAC reduction follows sparse pair count.</Bullet>
        </div>
      </Card>
    </div>
  </Shell>
);

const Closing: Page = () => (
  <Shell pageNo="16" kicker="Conclusion" title="完整 attention 功能路徑已補齊；下一關是重新跑 synthesis 與 post-sim。">
    <div style={{ marginTop: 78, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 30 }}>
      {[
        ['What was built', 'Sparse QK、固定點 Softmax、weighted-V，以及具 backpressure 的 Q8.8 context 輸出。'],
        ['What is checked', 'Golden model 已加入四種 sparse mode 的 q、feature 與 context value 逐筆比對。'],
        ['What remains', '重新執行 VCS pre-sim、T18 synthesis 與更新後 gate-level post-sim。'],
      ].map(([head, body]) => (
        <Card key={head} style={{ padding: 40, minHeight: 344 }}>
          <div style={{ fontFamily: font.display, fontSize: 42, fontWeight: 800 }}>{head}</div>
          <div style={{ marginTop: 28, color: palette.soft, fontSize: 28, lineHeight: 1.5 }}>{body}</div>
        </Card>
      ))}
    </div>
    <Card style={{ marginTop: 42, padding: '28px 36px', fontSize: 26, lineHeight: 1.5, color: palette.soft }}>
      Tapeout 前必須把 dense score buffer 映射為 SRAM，並依 synthesis 結果替換或 pipeline normalization divider。
    </Card>
  </Shell>
);

export const meta: SlideMeta = {
  title: 'Sparse Attention RTL Implementation Report',
};

export const design = {
  palette: {
    bg: palette.bg,
    text: palette.text,
    accent: palette.copper,
  },
  fonts: {
    display: font.display,
    body: font.body,
  },
  typeScale: {
    hero: 104,
    body: 30,
  },
  radius: 8,
};

export default [
  Cover,
  PreReview1,
  PreReview2,
  PreReview3,
  ImplementationScope,
  Architecture,
  FullAttentionPath,
  SoftmaxAndSV,
  ExperimentPlan,
  Workload,
  PythonResult,
  PresimResult,
  PostsimResult,
  SoftwareHardwareComparison,
  ReductionSummary,
  Closing,
] satisfies Page[];
