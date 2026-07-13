import type React from 'react';
import type { DesignSystem, Page, SlideMeta } from '@open-slide/core';
import { useSlidePageNumber } from '@open-slide/core';

import bedsideConceptPhoto from './assets/bedside-concept.jpg';
import careTugPhoto from './assets/care-tug-corridor.png';
import transportPainPhoto from './assets/transport-pain.png';

export const design: DesignSystem = {
  palette: { bg: '#f7fafb', text: '#122033', accent: '#16a6a3' },
  fonts: {
    display: '"Aptos Display", "Microsoft JhengHei", system-ui, sans-serif',
    body: '"Aptos", "Microsoft JhengHei", system-ui, sans-serif',
  },
  typeScale: { hero: 132, body: 34 },
  radius: 8,
};

const navy = '#122033';
const teal = '#16a6a3';
const tealDark = '#0b7f7e';
const coral = '#f06449';
const blue = '#2f6fed';
const sky = '#d9eef6';
const mint = '#dff5ef';
const paper = '#ffffff';
const line = '#d8e5ea';
const muted = '#607286';
const pale = '#eef6f8';
const amber = '#f4b942';
const green = '#2fbf71';
const red = '#d94f4f';

const fill: React.CSSProperties = {
  width: '100%',
  height: '100%',
  background: 'var(--osd-bg)',
  color: 'var(--osd-text)',
  fontFamily: 'var(--osd-font-body)',
  position: 'relative',
  overflow: 'hidden',
  letterSpacing: 0,
};

const pagePad = 104;

const Grid = () => (
  <div
    style={{
      position: 'absolute',
      inset: 0,
      backgroundImage:
        'linear-gradient(rgba(18,32,51,0.045) 1px, transparent 1px), linear-gradient(90deg, rgba(18,32,51,0.045) 1px, transparent 1px)',
      backgroundSize: '96px 96px',
      opacity: 0.75,
    }}
  />
);

const Footer = ({ label = 'BedMove Care System' }: { label?: string }) => {
  const { current, total } = useSlidePageNumber();
  return (
    <div
      style={{
        position: 'absolute',
        left: pagePad,
        right: pagePad,
        bottom: 34,
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        color: muted,
        fontSize: 18,
        fontWeight: 700,
      }}
    >
      <span>{label}</span>
      <span>
        {String(current).padStart(2, '0')} / {String(total).padStart(2, '0')}
      </span>
    </div>
  );
};

const Kicker = ({ children }: { children: React.ReactNode }) => (
  <div style={{ display: 'flex', alignItems: 'center', gap: 16, color: tealDark, fontSize: 22, fontWeight: 900 }}>
    <div style={{ width: 52, height: 5, background: teal, borderRadius: 4 }} />
    <div>{children}</div>
  </div>
);

const SlideTitle = ({ kicker, title, width = 1240 }: { kicker: string; title: React.ReactNode; width?: number }) => (
  <>
    <Kicker>{kicker}</Kicker>
    <h1
      style={{
        width,
        margin: '22px 0 0',
        fontFamily: 'var(--osd-font-display)',
        fontSize: 66,
        lineHeight: 1.1,
        fontWeight: 900,
        letterSpacing: 0,
      }}
    >
      {title}
    </h1>
  </>
);

const Shell = ({
  kicker,
  title,
  children,
  titleWidth,
}: {
  kicker: string;
  title: React.ReactNode;
  children: React.ReactNode;
  titleWidth?: number;
}) => (
  <section style={fill}>
    <Grid />
    <main style={{ position: 'absolute', inset: 0, padding: `${pagePad}px ${pagePad}px 84px` }}>
      <SlideTitle kicker={kicker} title={title} width={titleWidth} />
      {children}
    </main>
    <Footer />
  </section>
);

const Card = ({
  children,
  style,
  tone = 'paper',
}: {
  children: React.ReactNode;
  style?: React.CSSProperties;
  tone?: 'paper' | 'tint' | 'dark';
}) => (
  <div
    style={{
      background: tone === 'dark' ? navy : tone === 'tint' ? pale : paper,
      border: `1px solid ${tone === 'dark' ? '#244059' : line}`,
      borderRadius: 8,
      boxShadow: tone === 'dark' ? 'none' : '0 18px 44px rgba(18, 32, 51, 0.08)',
      color: tone === 'dark' ? '#ffffff' : navy,
      ...style,
    }}
  >
    {children}
  </div>
);

const PhotoFrame = ({
  src,
  alt,
  style,
  fit = 'cover',
}: {
  src: string;
  alt: string;
  style?: React.CSSProperties;
  fit?: 'cover' | 'contain';
}) => (
  <div
    style={{
      position: 'relative',
      overflow: 'hidden',
      borderRadius: 8,
      background: paper,
      border: `1px solid ${line}`,
      boxShadow: '0 22px 54px rgba(18, 32, 51, 0.14)',
      ...style,
    }}
  >
    <img
      src={src}
      alt={alt}
      style={{ display: 'block', width: '100%', height: '100%', objectFit: fit }}
    />
  </div>
);

const Bullet = ({ children, color = teal }: { children: React.ReactNode; color?: string }) => (
  <div style={{ display: 'flex', gap: 18, alignItems: 'flex-start', fontSize: 31, lineHeight: 1.42, color: navy }}>
    <div style={{ width: 14, height: 14, marginTop: 15, borderRadius: 4, background: color }} />
    <div>{children}</div>
  </div>
);

const Tag = ({ children, color = teal }: { children: React.ReactNode; color?: string }) => (
  <div
    style={{
      display: 'inline-flex',
      alignItems: 'center',
      height: 42,
      padding: '0 16px',
      borderRadius: 8,
      background: `${color}18`,
      color,
      fontSize: 20,
      fontWeight: 900,
    }}
  >
    {children}
  </div>
);

const Bed = ({ scale = 1 }: { scale?: number }) => (
  <div style={{ position: 'relative', width: 420 * scale, height: 190 * scale }}>
    <div
      style={{
        position: 'absolute',
        left: 20 * scale,
        top: 70 * scale,
        width: 340 * scale,
        height: 68 * scale,
        borderRadius: 16 * scale,
        background: paper,
        border: `${3 * scale}px solid ${line}`,
      }}
    />
    <div style={{ position: 'absolute', left: 42 * scale, top: 45 * scale, width: 90 * scale, height: 42 * scale, borderRadius: 14 * scale, background: sky }} />
    <div style={{ position: 'absolute', left: 142 * scale, top: 56 * scale, width: 178 * scale, height: 28 * scale, borderRadius: 12 * scale, background: mint }} />
    <div style={{ position: 'absolute', left: 30 * scale, top: 138 * scale, width: 18 * scale, height: 36 * scale, background: '#8aa0b5' }} />
    <div style={{ position: 'absolute', left: 312 * scale, top: 138 * scale, width: 18 * scale, height: 36 * scale, background: '#8aa0b5' }} />
    <div style={{ position: 'absolute', left: 14 * scale, top: 168 * scale, width: 46 * scale, height: 12 * scale, borderRadius: 10 * scale, background: navy }} />
    <div style={{ position: 'absolute', left: 296 * scale, top: 168 * scale, width: 46 * scale, height: 12 * scale, borderRadius: 10 * scale, background: navy }} />
    <div style={{ position: 'absolute', right: 20 * scale, top: 30 * scale, width: 12 * scale, height: 118 * scale, borderRadius: 8 * scale, background: '#8aa0b5' }} />
  </div>
);

const Robot = ({ scale = 1, hook = true }: { scale?: number; hook?: boolean }) => (
  <div style={{ position: 'relative', width: 300 * scale, height: 150 * scale }}>
    <div
      style={{
        position: 'absolute',
        left: 36 * scale,
        top: 42 * scale,
        width: 220 * scale,
        height: 72 * scale,
        borderRadius: 38 * scale,
        background: 'linear-gradient(180deg, #ffffff 0%, #dcecf2 100%)',
        border: `${3 * scale}px solid #b9ccd5`,
        boxShadow: `0 ${18 * scale}px ${38 * scale}px rgba(18,32,51,0.16)`,
      }}
    />
    <div style={{ position: 'absolute', left: 82 * scale, top: 60 * scale, width: 94 * scale, height: 12 * scale, borderRadius: 999, background: teal }} />
    <div style={{ position: 'absolute', left: 198 * scale, top: 60 * scale, width: 26 * scale, height: 12 * scale, borderRadius: 999, background: blue }} />
    <div style={{ position: 'absolute', left: 76 * scale, top: 108 * scale, width: 38 * scale, height: 22 * scale, borderRadius: 999, background: navy }} />
    <div style={{ position: 'absolute', left: 186 * scale, top: 108 * scale, width: 38 * scale, height: 22 * scale, borderRadius: 999, background: navy }} />
    {hook ? (
      <>
        <div style={{ position: 'absolute', left: 214 * scale, top: 76 * scale, width: 70 * scale, height: 10 * scale, borderRadius: 999, background: '#7d93a8' }} />
        <div style={{ position: 'absolute', left: 278 * scale, top: 70 * scale, width: 18 * scale, height: 36 * scale, borderRadius: 999, border: `${5 * scale}px solid ${coral}`, borderLeft: 0 }} />
      </>
    ) : null}
  </div>
);

const RouteMap = () => (
  <Card style={{ position: 'relative', height: 398, padding: 28, overflow: 'hidden' }}>
    <div style={{ position: 'absolute', inset: 28, borderRadius: 8, background: '#f3f8fa', border: `1px solid ${line}` }} />
    <div style={{ position: 'absolute', left: 90, top: 110, width: 230, height: 140, borderRadius: 8, background: paper, border: `1px solid ${line}` }} />
    <div style={{ position: 'absolute', left: 410, top: 80, width: 240, height: 170, borderRadius: 8, background: paper, border: `1px solid ${line}` }} />
    <div style={{ position: 'absolute', left: 725, top: 132, width: 230, height: 150, borderRadius: 8, background: paper, border: `1px solid ${line}` }} />
    <div style={{ position: 'absolute', left: 1045, top: 96, width: 250, height: 170, borderRadius: 8, background: paper, border: `1px solid ${line}` }} />
    <div style={{ position: 'absolute', left: 206, top: 177, width: 320, height: 8, background: teal, borderRadius: 8 }} />
    <div style={{ position: 'absolute', left: 524, top: 177, width: 320, height: 8, background: teal, borderRadius: 8, transform: 'rotate(7deg)', transformOrigin: 'left center' }} />
    <div style={{ position: 'absolute', left: 838, top: 196, width: 330, height: 8, background: teal, borderRadius: 8, transform: 'rotate(-9deg)', transformOrigin: 'left center' }} />
    <div style={{ position: 'absolute', left: 120, top: 136, fontSize: 28, fontWeight: 900 }}>病房</div>
    <div style={{ position: 'absolute', left: 444, top: 107, fontSize: 28, fontWeight: 900 }}>CT / MRI</div>
    <div style={{ position: 'absolute', left: 756, top: 162, fontSize: 28, fontWeight: 900 }}>手術室</div>
    <div style={{ position: 'absolute', left: 1080, top: 126, fontSize: 28, fontWeight: 900 }}>復健室</div>
    <div style={{ position: 'absolute', left: 176, top: 206 }}><Robot scale={0.45} /></div>
  </Card>
);

const Cover: Page = () => (
  <section style={fill}>
    <Grid />
    <div style={{ position: 'absolute', left: 116, top: 112 }}>
      <Kicker>Hospital Mobility Platform</Kicker>
      <h1
        style={{
          width: 1020,
          margin: '42px 0 0',
          fontFamily: 'var(--osd-font-display)',
          fontSize: 'var(--osd-size-hero)',
          lineHeight: 1.02,
          fontWeight: 900,
          letterSpacing: 0,
        }}
      >
        BedMove Care System
      </h1>
      <p style={{ margin: '40px 0 0', width: 900, color: muted, fontSize: 42, lineHeight: 1.38, fontWeight: 700 }}>
        不是只做一台拖病床的機器人，而是一套可排程、可追蹤、可管理的病床移動系統。
      </p>
    </div>
    <div style={{ position: 'absolute', right: 92, top: 122, width: 720, height: 670 }}>
      <PhotoFrame
        src={careTugPhoto}
        alt="Hospital bed transport robot connected to a bed in a corridor"
        style={{ width: 720, height: 520 }}
      />
      <div style={{ position: 'absolute', left: 38, bottom: 0, display: 'flex', gap: 18 }}>
        <Tag>排程</Tag>
        <Tag color={blue}>路線</Tag>
        <Tag color={coral}>安全</Tag>
      </div>
      <Card style={{ position: 'absolute', right: 34, bottom: 48, width: 270, padding: '22px 24px' }}>
        <div style={{ color: muted, fontSize: 20, fontWeight: 800 }}>概念主張</div>
        <div style={{ marginTop: 8, fontSize: 30, lineHeight: 1.18, fontWeight: 900 }}>醫療級病床移動平台</div>
      </Card>
    </div>
    <Footer label="System proposal deck" />
  </section>
);

const PainPoints: Page = () => (
  <Shell kicker="Problem" title="病床移動不是單一動作，而是醫院每天反覆發生的協調成本。">
    <div style={{ marginTop: 54, display: 'grid', gridTemplateColumns: '0.9fr 1.1fr', gap: 34 }}>
      <Card style={{ padding: 38, height: 610 }}>
        <div style={{ fontSize: 36, fontWeight: 900 }}>現況流程</div>
        <div style={{ marginTop: 38, display: 'flex', flexDirection: 'column', gap: 28 }}>
          <Bullet color={coral}>護理師、傳送人員、家屬協助推床</Bullet>
          <Bullet color={coral}>臨時排程用電話與口頭確認串接</Bullet>
          <Bullet color={coral}>病床位置與任務狀態難即時掌握</Bullet>
          <Bullet color={coral}>非醫療工作佔用護理時間</Bullet>
        </div>
      </Card>
      <Card style={{ padding: 22, height: 610 }}>
        <PhotoFrame
          src={transportPainPhoto}
          alt="Busy hospital corridor with beds waiting for patient transport"
          style={{ height: 456, boxShadow: 'none' }}
        />
        <div style={{ marginTop: 20, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 14 }}>
          <div style={{ color: muted, fontSize: 25, fontWeight: 900 }}>人力不足</div>
          <div style={{ color: muted, fontSize: 25, fontWeight: 900 }}>等待時間長</div>
          <div style={{ color: muted, fontSize: 25, fontWeight: 900 }}>位置不透明</div>
        </div>
      </Card>
    </div>
  </Shell>
);

const Overview: Page = () => (
  <Shell kicker="Solution" title="BedMove Care System 把機器人、排程與管理平台整合成一套流程。">
    <div style={{ marginTop: 52, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 28 }}>
      <Card style={{ padding: 34, minHeight: 470 }}>
        <Tag>01</Tag>
        <div style={{ marginTop: 28 }}><Robot scale={1.18} /></div>
        <h3 style={{ margin: '28px 0 0', fontSize: 40, lineHeight: 1.1 }}>病床移動機器人</h3>
        <p style={{ margin: '18px 0 0', color: muted, fontSize: 28, lineHeight: 1.42 }}>低矮醫療設備外型，透過油壓鉤連接病床底部。</p>
      </Card>
      <Card style={{ padding: 34, minHeight: 470 }}>
        <Tag color={blue}>02</Tag>
        <div style={{ marginTop: 30, display: 'grid', gap: 14 }}>
          <div style={{ height: 58, borderRadius: 8, background: '#eef4ff', border: `1px solid ${line}`, padding: '13px 18px', fontSize: 24, fontWeight: 900 }}>09:00 CT 檢查</div>
          <div style={{ height: 58, borderRadius: 8, background: '#eef4ff', border: `1px solid ${line}`, padding: '13px 18px', fontSize: 24, fontWeight: 900 }}>11:00 洗澡區</div>
          <div style={{ height: 58, borderRadius: 8, background: '#eef4ff', border: `1px solid ${line}`, padding: '13px 18px', fontSize: 24, fontWeight: 900 }}>14:00 術前準備</div>
        </div>
        <h3 style={{ margin: '30px 0 0', fontSize: 40, lineHeight: 1.1 }}>每日排程系統</h3>
        <p style={{ margin: '18px 0 0', color: muted, fontSize: 28, lineHeight: 1.42 }}>依檢查與手術時間自動安排任務。</p>
      </Card>
      <Card style={{ padding: 34, minHeight: 470 }}>
        <Tag color={coral}>03</Tag>
        <div style={{ marginTop: 30, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
          <div style={{ height: 86, borderRadius: 8, background: mint, padding: 14, fontSize: 22, fontWeight: 900 }}>Online<br /><span style={{ color: green }}>4 台</span></div>
          <div style={{ height: 86, borderRadius: 8, background: '#fff3e8', padding: 14, fontSize: 22, fontWeight: 900 }}>待修<br /><span style={{ color: coral }}>1 台</span></div>
          <div style={{ height: 86, borderRadius: 8, background: pale, padding: 14, fontSize: 22, fontWeight: 900 }}>任務中<br /><span style={{ color: teal }}>2 台</span></div>
          <div style={{ height: 86, borderRadius: 8, background: '#eef4ff', padding: 14, fontSize: 22, fontWeight: 900 }}>充電中<br /><span style={{ color: blue }}>1 台</span></div>
        </div>
        <h3 style={{ margin: '30px 0 0', fontSize: 40, lineHeight: 1.1 }}>Dashboard 管理平台</h3>
        <p style={{ margin: '18px 0 0', color: muted, fontSize: 28, lineHeight: 1.42 }}>掌握機器人狀態、位置與下一個任務。</p>
      </Card>
    </div>
  </Shell>
);

const FormDesign: Page = () => (
  <Shell kicker="Robot Design" title="外型不能像倉儲 AGV，必須讓病人感覺它是醫療設備。">
    <div style={{ marginTop: 48, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 36 }}>
      <Card style={{ height: 610, padding: 28 }}>
        <PhotoFrame
          src={careTugPhoto}
          alt="Low-profile hospital towing robot connected to a bed"
          style={{ height: 398, boxShadow: 'none' }}
        />
        <div style={{ marginTop: 24, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 18 }}>
          <Tag>低矮流線型</Tag>
          <Tag>白色醫療外殼</Tag>
          <Tag color={blue}>圓角設計</Tag>
          <Tag color={coral}>工作指示燈</Tag>
        </div>
      </Card>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 22 }}>
        <Card style={{ padding: 30 }}>
          <Bullet>服務對象是病人，不是貨物；造型語彙要降低壓迫感。</Bullet>
        </Card>
        <Card style={{ padding: 30 }}>
          <Bullet color={blue}>前方或床尾底部伸出油壓鉤，保持病床整體穩定。</Bullet>
        </Card>
        <Card style={{ padding: 30 }}>
          <Bullet color={coral}>燈號只傳達必要狀態，不做過度工業化警示。</Bullet>
        </Card>
      </div>
    </div>
  </Shell>
);

const Mechanism: Page = () => (
  <Shell kicker="Mechanism" title="油壓鉤只連接病床底部，不抬起病人，重點是穩定拖動。">
    <div style={{ marginTop: 50, display: 'grid', gridTemplateColumns: '1.12fr 0.88fr', gap: 36 }}>
      <Card style={{ height: 604, padding: 28 }}>
        <PhotoFrame
          src={bedsideConceptPhoto}
          alt="Hospital bed with a compact robot beside it"
          style={{ height: 456, boxShadow: 'none' }}
        />
        <div style={{ marginTop: 22, display: 'flex', gap: 16, alignItems: 'center' }}>
          <Tag color={coral}>鎖定確認後才啟動</Tag>
          <div style={{ color: muted, fontSize: 24, lineHeight: 1.35, fontWeight: 800 }}>
            連接病床底部結構，穩定拖動整張病床。
          </div>
        </div>
      </Card>
      <Card style={{ padding: 36 }}>
        <h3 style={{ margin: 0, fontSize: 42, lineHeight: 1.1 }}>關鍵安全設計</h3>
        <div style={{ marginTop: 34, display: 'flex', flexDirection: 'column', gap: 24 }}>
          <Bullet>自動對位病床底部</Bullet>
          <Bullet>油壓鉤伸縮與鎖定感測</Bullet>
          <Bullet>未確認鎖定不能啟動</Bullet>
          <Bullet color={coral}>緊急停止按鈕與人工接管</Bullet>
        </div>
      </Card>
    </div>
  </Shell>
);

const Workflow: Page = () => (
  <Shell kicker="Workflow" title="每一次病床移動都變成可紀錄、可回報的六步任務。">
    <div style={{ marginTop: 52, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 22 }}>
      <Card style={{ padding: 26, height: 204 }}><Tag>1</Tag><h3 style={{ margin: '20px 0 0', fontSize: 34 }}>系統接收任務</h3><p style={{ fontSize: 24, color: muted }}>從排程或護理站派單</p></Card>
      <Card style={{ padding: 26, height: 204 }}><Tag>2</Tag><h3 style={{ margin: '20px 0 0', fontSize: 34 }}>前往病床位置</h3><p style={{ fontSize: 24, color: muted }}>依路線導航到病房</p></Card>
      <Card style={{ padding: 26, height: 204 }}><Tag>3</Tag><h3 style={{ margin: '20px 0 0', fontSize: 34 }}>對準病床底部</h3><p style={{ fontSize: 24, color: muted }}>低速定位與安全檢查</p></Card>
      <Card style={{ padding: 26, height: 204 }}><Tag color={blue}>4</Tag><h3 style={{ margin: '20px 0 0', fontSize: 34 }}>伸出油壓鉤</h3><p style={{ fontSize: 24, color: muted }}>扣住底部結構並確認</p></Card>
      <Card style={{ padding: 26, height: 204 }}><Tag color={blue}>5</Tag><h3 style={{ margin: '20px 0 0', fontSize: 34 }}>移動到目的地</h3><p style={{ fontSize: 24, color: muted }}>走廊、電梯、科室路線</p></Card>
      <Card style={{ padding: 26, height: 204 }}><Tag color={green}>6</Tag><h3 style={{ margin: '20px 0 0', fontSize: 34 }}>回報任務完成</h3><p style={{ fontSize: 24, color: muted }}>解除鎖定並更新狀態</p></Card>
    </div>
    <div style={{ marginTop: 32 }}>
      <RouteMap />
    </div>
  </Shell>
);

const Schedule: Page = () => (
  <Shell kicker="Scheduling Platform" title="核心價值在排程：自動安排哪台機器人、何時接人、走哪條路。">
    <div style={{ marginTop: 48, display: 'grid', gridTemplateColumns: '0.86fr 1.14fr', gap: 34 }}>
      <Card style={{ padding: 34, height: 610 }}>
        <h3 style={{ margin: 0, fontSize: 42 }}>病人 A 今日移動</h3>
        <div style={{ marginTop: 34, display: 'flex', flexDirection: 'column', gap: 20 }}>
          <div style={{ display: 'grid', gridTemplateColumns: '120px 1fr', gap: 18, alignItems: 'center' }}><Tag>09:00</Tag><div style={{ fontSize: 31, fontWeight: 900 }}>CT 檢查</div></div>
          <div style={{ display: 'grid', gridTemplateColumns: '120px 1fr', gap: 18, alignItems: 'center' }}><Tag color={blue}>11:00</Tag><div style={{ fontSize: 31, fontWeight: 900 }}>洗澡區</div></div>
          <div style={{ display: 'grid', gridTemplateColumns: '120px 1fr', gap: 18, alignItems: 'center' }}><Tag color={coral}>14:00</Tag><div style={{ fontSize: 31, fontWeight: 900 }}>術前準備室</div></div>
          <div style={{ display: 'grid', gridTemplateColumns: '120px 1fr', gap: 18, alignItems: 'center' }}><Tag color={green}>16:00</Tag><div style={{ fontSize: 31, fontWeight: 900 }}>回病房</div></div>
        </div>
        <p style={{ marginTop: 42, color: muted, fontSize: 28, lineHeight: 1.48 }}>護理站可以即時看到病人目前位置與下一段移動狀態。</p>
      </Card>
      <Card style={{ padding: 34, height: 610 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 16 }}>
          <div style={{ height: 104, borderRadius: 8, background: mint, padding: 18 }}><div style={{ fontSize: 20, color: muted, fontWeight: 800 }}>Robot</div><div style={{ fontSize: 34, fontWeight: 900 }}>R-03</div></div>
          <div style={{ height: 104, borderRadius: 8, background: '#eef4ff', padding: 18 }}><div style={{ fontSize: 20, color: muted, fontWeight: 800 }}>Route</div><div style={{ fontSize: 34, fontWeight: 900 }}>B2 到 CT</div></div>
          <div style={{ height: 104, borderRadius: 8, background: '#fff3e8', padding: 18 }}><div style={{ fontSize: 20, color: muted, fontWeight: 800 }}>ETA</div><div style={{ fontSize: 34, fontWeight: 900 }}>7 min</div></div>
        </div>
        <div style={{ marginTop: 28, position: 'relative', height: 396, borderRadius: 8, background: '#f2f7f9', border: `1px solid ${line}` }}>
          <div style={{ position: 'absolute', left: 52, top: 52, width: 700, height: 10, background: teal, borderRadius: 8 }} />
          <div style={{ position: 'absolute', left: 52, top: 52, width: 10, height: 250, background: teal, borderRadius: 8 }} />
          <div style={{ position: 'absolute', left: 52, top: 292, width: 700, height: 10, background: teal, borderRadius: 8 }} />
          <div style={{ position: 'absolute', left: 92, top: 92 }}><Robot scale={0.62} /></div>
          <div style={{ position: 'absolute', left: 522, top: 204 }}><Bed scale={0.58} /></div>
          <div style={{ position: 'absolute', left: 70, top: 330, fontSize: 24, fontWeight: 900, color: muted }}>路線狀態：已派車，等待護理師授權</div>
        </div>
      </Card>
    </div>
  </Shell>
);

const Dashboard: Page = () => (
  <Shell kicker="Dashboard" title="管理者從人工打電話找人，轉成系統化掌握全院移動資源。">
    <div style={{ marginTop: 48, display: 'grid', gridTemplateColumns: '1.15fr 0.85fr', gap: 34 }}>
      <Card style={{ padding: 30, height: 610 }}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: 14 }}>
          <div style={{ borderRadius: 8, background: mint, padding: 16, height: 96 }}><div style={{ color: muted, fontSize: 18, fontWeight: 800 }}>Online</div><div style={{ fontSize: 38, fontWeight: 900 }}>08</div></div>
          <div style={{ borderRadius: 8, background: pale, padding: 16, height: 96 }}><div style={{ color: muted, fontSize: 18, fontWeight: 800 }}>任務中</div><div style={{ fontSize: 38, fontWeight: 900 }}>03</div></div>
          <div style={{ borderRadius: 8, background: '#eef4ff', padding: 16, height: 96 }}><div style={{ color: muted, fontSize: 18, fontWeight: 800 }}>充電中</div><div style={{ fontSize: 38, fontWeight: 900 }}>02</div></div>
          <div style={{ borderRadius: 8, background: '#fff3e8', padding: 16, height: 96 }}><div style={{ color: muted, fontSize: 18, fontWeight: 800 }}>異常</div><div style={{ fontSize: 38, fontWeight: 900, color: coral }}>01</div></div>
        </div>
        <div style={{ marginTop: 24, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 18 }}>
          <Card tone="tint" style={{ padding: 18, height: 170 }}><Tag>R-03</Tag><div style={{ marginTop: 18, fontSize: 28, fontWeight: 900 }}>病房 B2 到 CT</div><div style={{ marginTop: 12, height: 12, borderRadius: 8, background: line }}><div style={{ width: '64%', height: '100%', background: teal, borderRadius: 8 }} /></div></Card>
          <Card tone="tint" style={{ padding: 18, height: 170 }}><Tag color={green}>R-05</Tag><div style={{ marginTop: 18, fontSize: 28, fontWeight: 900 }}>待命：護理站</div><div style={{ marginTop: 12, color: muted, fontSize: 22 }}>電量 91%</div></Card>
          <Card tone="tint" style={{ padding: 18, height: 170 }}><Tag color={blue}>R-07</Tag><div style={{ marginTop: 18, fontSize: 28, fontWeight: 900 }}>充電中</div><div style={{ marginTop: 12, color: muted, fontSize: 22 }}>預計 18 分鐘</div></Card>
          <Card tone="tint" style={{ padding: 18, height: 170 }}><Tag color={coral}>R-02</Tag><div style={{ marginTop: 18, fontSize: 28, fontWeight: 900 }}>待修：感測器</div><div style={{ marginTop: 12, color: muted, fontSize: 22 }}>需工程師確認</div></Card>
        </div>
      </Card>
      <Card style={{ padding: 34, height: 610 }}>
        <h3 style={{ margin: 0, fontSize: 42 }}>平台看到的狀態</h3>
        <div style={{ marginTop: 34, display: 'flex', flexDirection: 'column', gap: 22 }}>
          <Bullet>Online / Offline / 任務中 / 待命</Bullet>
          <Bullet>電量、位置、下一個任務</Bullet>
          <Bullet>維修警示與異常警報</Bullet>
          <Bullet color={blue}>任務路線與抵達時間</Bullet>
        </div>
      </Card>
    </div>
  </Shell>
);

const Safety: Page = () => (
  <Shell kicker="Safety" title="因為運送的是病人，所以安全比速度更重要。">
    <div style={{ marginTop: 50, display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 22 }}>
      <Card style={{ padding: 28, minHeight: 250 }}><Tag>低速</Tag><h3 style={{ fontSize: 34, margin: '28px 0 0' }}>穩定移動</h3><p style={{ color: muted, fontSize: 25, lineHeight: 1.4 }}>限制速度與轉彎加速度。</p></Card>
      <Card style={{ padding: 28, minHeight: 250 }}><Tag color={blue}>避障</Tag><h3 style={{ fontSize: 34, margin: '28px 0 0' }}>雷達與攝影機</h3><p style={{ color: muted, fontSize: 25, lineHeight: 1.4 }}>走廊人流與障礙偵測。</p></Card>
      <Card style={{ padding: 28, minHeight: 250 }}><Tag color={coral}>授權</Tag><h3 style={{ fontSize: 34, margin: '28px 0 0' }}>護理師確認</h3><p style={{ color: muted, fontSize: 25, lineHeight: 1.4 }}>啟動前確認病人身份。</p></Card>
      <Card style={{ padding: 28, minHeight: 250 }}><Tag color={red}>急停</Tag><h3 style={{ fontSize: 34, margin: '28px 0 0' }}>可人工接管</h3><p style={{ color: muted, fontSize: 25, lineHeight: 1.4 }}>斷線或異常立即停車。</p></Card>
    </div>
    <Card style={{ marginTop: 32, height: 330, padding: 30 }}>
      <div style={{ position: 'relative', height: '100%' }}>
        <div style={{ position: 'absolute', left: 94, top: 42 }}><Bed scale={1.06} /></div>
        <div style={{ position: 'absolute', left: 470, top: 172 }}><Robot scale={1.08} /></div>
        <div style={{ position: 'absolute', left: 805, top: 56, width: 210, height: 146, borderRadius: 8, background: '#101b2b', padding: 20, color: '#fff' }}>
          <div style={{ fontSize: 24, fontWeight: 900 }}>Nurse Tablet</div>
          <div style={{ marginTop: 20, height: 42, borderRadius: 8, background: teal, padding: '8px 14px', fontSize: 20, fontWeight: 900 }}>授權啟動</div>
          <div style={{ marginTop: 12, height: 42, borderRadius: 8, background: coral, padding: '8px 14px', fontSize: 20, fontWeight: 900 }}>緊急停止</div>
        </div>
        <div style={{ position: 'absolute', right: 70, top: 88, width: 360, color: muted, fontSize: 30, lineHeight: 1.45, fontWeight: 800 }}>
          讓評審相信：這不是危險的搬運機器，而是醫療級流程。
        </div>
      </div>
    </Card>
  </Shell>
);

const BusinessModel: Page = () => (
  <Shell kicker="Business Model" title="比起單純賣機器人，更適合做成長期醫療服務。">
    <div style={{ marginTop: 56, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 28 }}>
      <Card style={{ padding: 36, height: 430 }}><Tag>硬體租賃</Tag><h3 style={{ margin: '34px 0 0', fontSize: 44 }}>機器人月租</h3><p style={{ marginTop: 24, color: muted, fontSize: 30, lineHeight: 1.42 }}>醫院可以從小規模試點開始，不需要一次買斷。</p></Card>
      <Card style={{ padding: 36, height: 430 }}><Tag color={blue}>系統月費</Tag><h3 style={{ margin: '34px 0 0', fontSize: 44 }}>Dashboard 訂閱</h3><p style={{ marginTop: 24, color: muted, fontSize: 30, lineHeight: 1.42 }}>排程、派車、路線與狀態管理形成持續收入。</p></Card>
      <Card style={{ padding: 36, height: 430 }}><Tag color={coral}>維護合約</Tag><h3 style={{ margin: '34px 0 0', fontSize: 44 }}>整合與保養</h3><p style={{ marginTop: 24, color: muted, fontSize: 30, lineHeight: 1.42 }}>包含醫院系統整合、保養與後續資料分析。</p></Card>
    </div>
    <Card tone="dark" style={{ marginTop: 40, padding: '34px 44px', display: 'grid', gridTemplateColumns: '360px 1fr', gap: 34, alignItems: 'center' }}>
      <div style={{ fontSize: 46, fontWeight: 900 }}>收入組合</div>
      <div style={{ display: 'flex', gap: 18 }}>
        <Tag>租賃</Tag>
        <Tag color={blue}>訂閱</Tag>
        <Tag color={amber}>維護</Tag>
        <Tag color={coral}>整合</Tag>
        <Tag color={green}>資料服務</Tag>
      </div>
    </Card>
  </Shell>
);

const Rollout: Page = () => (
  <Shell kicker="Rollout" title="導入不能一開始就全院上線，應該分階段降低風險。">
    <div style={{ marginTop: 76, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 30 }}>
      <Card style={{ padding: 40, height: 520 }}>
        <Tag>Phase 1</Tag>
        <h3 style={{ margin: '36px 0 0', fontSize: 48, lineHeight: 1.1 }}>病房到檢查室</h3>
        <p style={{ marginTop: 30, color: muted, fontSize: 31, lineHeight: 1.45 }}>先跑固定路線，驗證安全、對位與派車流程。</p>
      </Card>
      <Card style={{ padding: 40, height: 520 }}>
        <Tag color={blue}>Phase 2</Tag>
        <h3 style={{ margin: '36px 0 0', fontSize: 48, lineHeight: 1.1 }}>洗澡區與復健室</h3>
        <p style={{ marginTop: 30, color: muted, fontSize: 31, lineHeight: 1.45 }}>擴大到更多日常服務，讓護理站看到位置與狀態。</p>
      </Card>
      <Card style={{ padding: 40, height: 520 }}>
        <Tag color={coral}>Phase 3</Tag>
        <h3 style={{ margin: '36px 0 0', fontSize: 48, lineHeight: 1.1 }}>整合電梯與門禁</h3>
        <p style={{ marginTop: 30, color: muted, fontSize: 31, lineHeight: 1.45 }}>串接醫院排程系統，形成智慧醫院物流平台。</p>
      </Card>
    </div>
  </Shell>
);

const Vision: Page = () => (
  <section style={fill}>
    <Grid />
    <div style={{ position: 'absolute', left: 118, top: 106, width: 760 }}>
      <Kicker>Vision</Kicker>
      <h1 style={{ margin: '34px 0 0', fontFamily: 'var(--osd-font-display)', fontSize: 92, lineHeight: 1.08, fontWeight: 900, letterSpacing: 0 }}>
        不是讓機器人搬床，而是讓醫院的病人移動流程變聰明。
      </h1>
      <div style={{ marginTop: 42, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 18 }}>
        <Tag>可預約</Tag>
        <Tag color={blue}>可追蹤</Tag>
        <Tag color={coral}>可管理</Tag>
        <Tag color={green}>可最佳化</Tag>
      </div>
    </div>
    <div style={{ position: 'absolute', right: 94, top: 150, width: 760, height: 620 }}>
      <Card style={{ position: 'absolute', inset: 0, padding: 38 }}>
        <div style={{ position: 'absolute', left: 78, top: 102 }}><Bed scale={1.1} /></div>
        <div style={{ position: 'absolute', left: 424, top: 294 }}><Robot scale={1.22} /></div>
        <div style={{ position: 'absolute', left: 120, top: 430, width: 520, height: 10, borderRadius: 8, background: teal }} />
        <div style={{ position: 'absolute', left: 122, top: 474, color: muted, fontSize: 30, lineHeight: 1.45, fontWeight: 800 }}>
          把護理師從重複性搬運與協調工作中解放出來，讓時間回到醫療照護本身。
        </div>
      </Card>
    </div>
    <Footer label="Conclusion" />
  </section>
);

export const meta: SlideMeta = {
  title: 'BedMove Care System',
  createdAt: '2026-06-19T12:16:11.056Z',
};

export default [
  Cover,
  PainPoints,
  Overview,
  FormDesign,
  Mechanism,
  Workflow,
  Schedule,
  Dashboard,
  Safety,
  BusinessModel,
  Rollout,
  Vision,
] satisfies Page[];
