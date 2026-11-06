// AurumPulse_Research_v2.mq5
// Diagnostic research build. No module passed cost-adjusted validation.
// MQL5 compilation and real-tick execution must be performed in MetaTrader.
#property strict
#property version "2.00"

input group "Identity and switches"
input string InpSymbol="";                  // Empty = chart symbol; use exact broker name
input ulong  InpMagic=26011002;
input bool   InpEnableEntries=false;
input bool   InpResetSafetyState=false;      // Explicit operator reset on initialization
input bool   InpVerbose=true;

input group "Broker-server sessions; start inclusive, end exclusive"
input bool   InpAsia=true;
input string InpAsiaStart="00:00";
input string InpAsiaEnd="09:00";
input bool   InpLondon=true;
input string InpLondonStart="07:00";
input string InpLondonEnd="17:00";
input bool   InpNewYork=true;
input string InpNewYorkStart="12:00";
input string InpNewYorkEnd="00:00";

input group "Signals; all indicator shifts >= 1"
input bool   InpPullback=false;           // Module B
input bool   InpBreakout=false;           // Module D
input int    InpFastM1=9;
input int    InpSlowM1=21;
input int    InpFastM5=20;
input int    InpSlowM5=50;
input int    InpSlopeBars=3;
input double InpSlopeATR=0.05;
input int    InpATRPeriod=14;
input int    InpATRBaseline=40;
input int    InpVolumeBars=20;
input int    InpBreakoutBars=10;
input int    InpStructureBars=60;
input double InpBodyFraction=0.25;
input double InpCloseLocation=0.65;
input double InpPullbackToleranceATR=0.20;
input double InpMomentumATR=0.10;
input double InpVolumeExpansion=1.30;
input double InpBreakoutBufferATR=0.05;
input double InpRetestToleranceATR=0.20;
input double InpMaxChaseATR=0.45;
input double InpMinBreakoutRangeATR=0.80;
input double InpMaxBreakoutRangeATR=1.80;
input double InpMaxRetestRangeATR=2.20;
input double InpExpandATR=1.30;
input double InpExtremeATR=2.20;
input double InpExpandRange=1.60;
input double InpExtremeRange=3.00;
input int    InpMinScore=0;               // Ranking only; no calibrated probability
input int    InpHighScore=85;

input group "Sizing; percentages of equity; costs in account currency"
input double InpBaseRiskPct=0.05;
input double InpHighMultiplier=1.00;      // No unvalidated score-based leverage
input double InpExtremeRiskMultiplier=0.50;
input double InpMaxTradeRiskPct=0.10;
input double InpMinLot=0.01;
input double InpMaxLot=1.00;
input double InpMaxOpenRiskPct=0.30;       // All account positions, mark-to-stop or entry risk
input int    InpMaxPositions=1;            // This symbol and magic; netting always <= 1
input bool   InpAllowPyramiding=false;     // Hedging only; profitable AND cost-protected
input double InpScaleSpacingATR=0.25;
input double InpMaxMarginUsagePct=25.0;
input double InpCostPerLot=7.0;            // Round-trip commission/fee reserve per lot
input int    InpRiskSlipPoints=30;          // Adverse entry and stop-fill reserve, not guarantee

input group "Initial stops and targets"
input double InpStopATRNormal=1.60;
input double InpStopATRExpanding=1.60;
input double InpStopATRExtreme=1.80;
input double InpStructureBufferATR=0.12;
input double InpMaxStopATR=3.50;
input double InpTargetR=1.00;
input double InpMinTargetR=0.50;
input bool   InpCapTPAtStructure=false;
input int    InpStopSafetyPoints=5;

input group "Profit protection; original R is persisted per position"
input double InpBETriggerR=1.00;
input double InpBEOffsetATR=0.05;
input double InpLockTriggerR=1.40;
input double InpLockR=0.30;
input double InpTrailStartR=1.40;
input double InpTrailATR=1.20;
input bool   InpSwingTrail=false;
input int    InpSwingTrailBars=3;
input int    InpTrailStepPoints=10;
input int    InpModifyIntervalSeconds=2;

input group "Execution and live market safeguards; point != dollar"
input int    InpMaxSpreadPoints=60;
input double InpMaxSpreadATR=0.18;          // 0 disables this ratio gate
input double InpAbnormalSpreadRatio=3.00;
input double InpSpreadEWMAAlpha=0.05;       // Sample at most once per server second
input int    InpDeviationPoints=30;
input double InpMaxJumpATR=0.80;            // Consecutive-quote jump, including gaps
input double InpMaxSpeedATRPerSec=2.50;
input int    InpMaxTickAgeSeconds=5;
input int    InpMaxSignalAgeSeconds=10;
input int    InpErrorCooldownSeconds=10;
input int    InpShockCooldownSeconds=5;
input bool   InpSafeRequoteRetry=true;       // One retry only on definitive non-fill

input group "Emergency safety; NOT daily trading limits"
input bool   InpEquityEmergency=true;
input double InpEquityDDPct=5.0;           // Persistent equity high-water mark
input bool   InpCloseOnEquityEmergency=true;
input int    InpMaxConsecutiveLosses=0;     // 0 disables; otherwise latched manual reset


input group "Research modules and observability"
input bool InpTrendContinuation=false; // A
input bool InpAcceleration=false;      // C
input bool InpRetest=false;            // E
input bool InpRange=true;              // F; least-bad validation reference, NOT accepted
input bool InpExpansion=false;         // G
input bool InpFailedBreakout=false;    // H
input int  InpContextMode=2;           // 0 M1, 1 M1+M5, 2 M1+M5+M15; neutral allowed
input int  InpVolumeMode=1;            // 0 ignore, 1 optional score, 2 require positive recorded tick volume
input bool InpAuditWhenDisabled=true;  // Evaluate candidates without sending requests
input bool InpDiagnosticCSV=true;
input int  InpSummaryEveryBars=60;
input bool InpUseSwingInitialStop=false;
input bool InpProfitProtection=false; // Bar proxy used fixed SL/TP, no BE/trailing
input int  InpMaxHoldingMinutes=10;    // 0 disables; NOT a daily break
input double InpAccelerationATR=0.35;
input double InpAccelerationFactor=1.25;
input double InpRangeFlatATR=0.25;
input double InpRangeMinWidthATR=1.50;
input double InpRangeMaxWidthATR=4.00;
input double InpRangeTouchATR=0.15;
input double InpRangeRecoverATR=0.10;
input double InpMinWickFraction=0.35;
input double InpExpansionMinRangeATR=1.60;
input double InpExpansionMaxRangeATR=2.50;
input double InpExpansionBody=0.65;
input double InpMaxEntryGapATR=0.75;
input double InpMaxAbsoluteSpread=0.0; // Price units; 0 uses point ceiling only
input bool InpStrictBrokerSessions=true;

struct Features {
   double atr,atrRatio,rangeRatio,volRatio,vol2,fast,slow;
   int bias,bias15,regime; bool hasVolume;
};
struct Signal { int dir,module,score,regime; double sl,tp,risk,rr; };
string S,K;
double pt,ts,spreadBase=0,atrCache=0,peak=0;
int digits;
int hFast=INVALID_HANDLE,hSlow=INVALID_HANDLE,hATR=INVALID_HANDLE;
int hHFast=INVALID_HANDLE,hHSlow=INVALID_HANDLE,hHATR=INVALID_HANDLE;
int h15Fast=INVALID_HANDLE,h15Slow=INVALID_HANDLE,h15ATR=INVALID_HANDLE;
int sessions[6];
bool hedge=false,eqHalt=false,lossHalt=false,uncertain=false,dirty=true;
datetime lastBar=0,holdUntil=0,spreadStamp=0,epoch=0;
long prevMsc=0;
double prevMid=0,liveSpeed=0,liveJump=0;
MqlRates bars[];
int diagFile=INVALID_HANDLE;
string stageReason="";
string counterNames[];long counterValues[];
long rawCounts[8],closedCount=0,closedWins=0;
double closedNet=0;
ulong pendingClosed[];
string testKeys[];
double testValues[]; // Isolated in-run state, including original R, in Strategy Tester

void Count(string label){
   for(int i=0;i<ArraySize(counterNames);i++) if(counterNames[i]==label){counterValues[i]++;return;}
   int n=ArraySize(counterNames);ArrayResize(counterNames,n+1);ArrayResize(counterValues,n+1);
   counterNames[n]=label;counterValues[n]=1;
}
bool Fail(string label){stageReason=label;return false;}
void Audit(string label,int module=0,int direction=0,int score=0){
   Count(label);
   if(diagFile!=INVALID_HANDLE){
      MqlTick t;ZeroMemory(t);SymbolInfoTick(S,t);
      FileWrite(diagFile,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),
         TimeToString(lastBar,TIME_DATE|TIME_MINUTES),label,module,direction,score,
         DoubleToString(t.ask-t.bid,digits),DoubleToString(atrCache,digits),
         AccountInfoDouble(ACCOUNT_EQUITY),eqHalt,lossHalt,uncertain);
   }
}
void Summary(){
   string text="AR2 counters (some gates are non-exclusive): ";
   for(int i=0;i<ArraySize(counterNames);i++) text+=counterNames[i]+"="+IntegerToString(counterValues[i])+" ";
   Print(text);
   for(int i=0;i<8;i++) PrintFormat("AR2 module %d raw directional signals=%I64d",i+1,rawCounts[i]);
   PrintFormat("AR2 observed closed lifecycles=%I64d wins=%I64d net=%.2f",closedCount,closedWins,closedNet);
   if(diagFile!=INVALID_HANDLE) FileFlush(diagFile);
}
bool ModuleEnabled(int m){
   switch(m){
      case 1:return InpTrendContinuation;case 2:return InpPullback;
      case 3:return InpAcceleration;case 4:return InpBreakout;
      case 5:return InpRetest;case 6:return InpRange;
      case 7:return InpExpansion;case 8:return InpFailedBreakout;
   }
   return false;
}
void QueueClosed(ulong id){
   if(id==0)return;
   for(int i=0;i<ArraySize(pendingClosed);i++)if(pendingClosed[i]==id)return;
   int n=ArraySize(pendingClosed);ArrayResize(pendingClosed,n+1);pendingClosed[n]=id;
}
void PollClosed(){
   for(int i=ArraySize(pendingClosed)-1;i>=0;i--){
      ulong id=pendingClosed[i];if(PositionAlive(id))continue;
      if(!HistorySelectByPosition(id))continue;
      bool own=false,foreign=false;double net=0,invol=0,outvol=0;
      for(int j=0;j<HistoryDealsTotal();j++){
         ulong d=HistoryDealGetTicket(j);long ty=HistoryDealGetInteger(d,DEAL_TYPE);
         if(ty!=DEAL_TYPE_BUY && ty!=DEAL_TYPE_SELL)continue;
         long en=HistoryDealGetInteger(d,DEAL_ENTRY);double v=HistoryDealGetDouble(d,DEAL_VOLUME);
         if(en==DEAL_ENTRY_IN){invol+=v;if((ulong)HistoryDealGetInteger(d,DEAL_MAGIC)==InpMagic)own=true;else foreign=true;}
         if(en==DEAL_ENTRY_OUT || en==DEAL_ENTRY_OUT_BY)outvol+=v;
         if(en==DEAL_ENTRY_INOUT)foreign=true; // This EA never reverses netted positions.
         net+=HistoryDealGetDouble(d,DEAL_PROFIT)+HistoryDealGetDouble(d,DEAL_COMMISSION)+HistoryDealGetDouble(d,DEAL_SWAP)+HistoryDealGetDouble(d,DEAL_FEE);
      }
      if(invol>outvol+1e-8)continue; // No premature finalization on unordered events.
      if(own && !foreign && Load(IDKey("done",id),0)==0){
         Save(IDKey("done",id),1);closedCount++;if(net>0)closedWins++;closedNet+=net;
         PrintFormat("AR2 CLOSED_LIFECYCLE id=%I64u net=%.2f",id,net);Audit("CLOSED_LIFECYCLE");
         if(!Tester()){
            GlobalVariableDel(Key(IDKey("r",id)));GlobalVariableDel(Key(IDKey("m",id)));
            GlobalVariableDel(Key(IDKey("b",id)));GlobalVariableDel(Key(IDKey("c",id)));GlobalVariableDel(Key(IDKey("z",id)));
         }
      }
      int n=ArraySize(pendingClosed);for(int j=i;j<n-1;j++)pendingClosed[j]=pendingClosed[j+1];ArrayResize(pendingClosed,n-1);
   }
}
bool Tester(){return (bool)MQLInfoInteger(MQL_TESTER);}
void Log(string text){if(InpVerbose) Print("AurumPulse: ",text);}
string Key(string x){return K+"."+x;}
double Load(string x,double fallback=0){
   if(Tester()){
      for(int i=0;i<ArraySize(testKeys);i++) if(testKeys[i]==x) return testValues[i];
      return fallback;
   }
   if(!GlobalVariableCheck(Key(x))) return fallback;
   return GlobalVariableGet(Key(x));
}
void Save(string x,double v){
   if(Tester()){
      int n=ArraySize(testKeys);
      for(int i=0;i<n;i++) if(testKeys[i]==x){testValues[i]=v;return;}
      ArrayResize(testKeys,n+1);ArrayResize(testValues,n+1);
      testKeys[n]=x;testValues[n]=v;return;
   }
   if(GlobalVariableSet(Key(x),v)==0){uncertain=true;Print("SAFETY: persistent-state write failed: ",Key(x));}
}
string IDKey(string tag,ulong id){return tag+StringFormat("%I64u",id);}
void Ambiguous(string reason){
   uncertain=true; Save("uncertain",1); Print("SAFETY LATCH: ",reason,
      "; reconcile orders/deals/positions before explicit reset.");
}
void Cooldown(int seconds){holdUntil=(datetime)MathMax((double)holdUntil,(double)(TimeCurrent()+seconds));}

double Down(double p){return NormalizeDouble(MathFloor(p/ts+1e-9)*ts,digits);}
double Up(double p){return NormalizeDouble(MathCeil(p/ts-1e-9)*ts,digits);}
double MinDistance(){
   long a=SymbolInfoInteger(S,SYMBOL_TRADE_STOPS_LEVEL);
   long b=SymbolInfoInteger(S,SYMBOL_TRADE_FREEZE_LEVEL);
   return MathMax((double)a,(double)b)*pt+InpStopSafetyPoints*pt+ts;
}
bool Buf(int handle,int shift,double &v){
   double a[1];
   if(handle==INVALID_HANDLE || BarsCalculated(handle)<=shift ||
      CopyBuffer(handle,0,shift,1,a)!=1 || !MathIsValidNumber(a[0])) return false;
   v=a[0]; return true;
}
bool ReadFeatures(Features &f){
   int need=MathMax(InpStructureBars+5,MathMax(InpBreakoutBars+5,MathMax(InpVolumeBars+4,InpSwingTrailBars+3)));
   ArraySetAsSeries(bars,true);
   if(CopyRates(S,PERIOD_M1,0,need,bars)!=need)return Fail("DATA_M1_NOT_READY");
   double hf,hs,old,ha,v,sum=0;
   if(!Buf(hFast,1,f.fast)||!Buf(hSlow,1,f.slow)||!Buf(hATR,1,f.atr))return Fail("DATA_M1_INDICATORS");
   f.bias=0;f.bias15=0;
   if(InpContextMode>=1){
      if(!Buf(hHFast,1,hf)||!Buf(hHSlow,1,hs)||!Buf(hHFast,1+InpSlopeBars,old)||!Buf(hHATR,1,ha)||ha<=0)return Fail("DATA_M5_NOT_READY");
      double slope=(hf-old)/ha;f.bias=(hf>hs&&slope>=InpSlopeATR)?1:((hf<hs&&slope<=-InpSlopeATR)?-1:0);
   }
   if(InpContextMode>=2){
      if(!Buf(h15Fast,1,hf)||!Buf(h15Slow,1,hs)||!Buf(h15Fast,1+InpSlopeBars,old)||!Buf(h15ATR,1,ha)||ha<=0)return Fail("DATA_M15_NOT_READY");
      double slope=(hf-old)/ha;f.bias15=(hf>hs&&slope>=InpSlopeATR)?1:((hf<hs&&slope<=-InpSlopeATR)?-1:0);
   }
   if(f.atr<=0)return Fail("ATR_NONPOSITIVE");
   for(int i=2;i<=InpATRBaseline+1;i++){if(!Buf(hATR,i,v))return Fail("DATA_ATR_HISTORY");sum+=v;}
   if(sum<=0)return Fail("ATR_BASELINE_NONPOSITIVE");
   f.atrRatio=f.atr/(sum/InpATRBaseline);f.rangeRatio=(bars[1].high-bars[1].low)/f.atr;
   sum=0;for(int i=3;i<3+InpVolumeBars;i++)sum+=(double)bars[i].tick_volume;
   f.hasVolume=sum>0 && bars[1].tick_volume>0;
   f.volRatio=f.hasVolume?(double)bars[1].tick_volume/(sum/InpVolumeBars):0;
   f.vol2=sum>0?(double)bars[2].tick_volume/(sum/InpVolumeBars):0;
   if(!f.hasVolume){Count("VOLUME_UNAVAILABLE");if(InpVolumeMode==2)return Fail("VOLUME_REQUIRED_MISSING");}
   f.regime=0;
   if(f.atrRatio>=InpExpandATR||f.rangeRatio>=InpExpandRange)f.regime=1;
   if(f.atrRatio>=InpExtremeATR||f.rangeRatio>=InpExtremeRange||liveSpeed>=InpMaxSpeedATRPerSec||liveJump>=InpMaxJumpATR)f.regime=2;
   atrCache=f.atr;return true;
}

int ParseTime(string text){
   string p[];
   if(StringLen(text)!=5 || StringGetCharacter(text,2)!=58 || StringSplit(text,58,p)!=2) return -1;
   for(int i=0;i<5;i++) if(i!=2 && (StringGetCharacter(text,i)<48 || StringGetCharacter(text,i)>57)) return -1;
   int h=(int)StringToInteger(p[0]),m=(int)StringToInteger(p[1]);
   if(h>23 || m>59) return -1;
   return h*60+m;
}
bool InWindow(int now,int a,int b){
   if(a==b) return true; // Equal times explicitly mean 24 hours
   return a<b ? (now>=a && now<b) : (now>=a || now<b);
}
bool UserSession(){
   MqlDateTime d; TimeToStruct(TimeCurrent(),d); int m=d.hour*60+d.min;
   return (InpAsia && InWindow(m,sessions[0],sessions[1])) ||
      (InpLondon && InWindow(m,sessions[2],sessions[3])) ||
      (InpNewYork && InWindow(m,sessions[4],sessions[5]));
}
bool BrokerSession(){
   MqlDateTime d; TimeToStruct(TimeCurrent(),d);
   int sec=d.hour*3600+d.min*60+d.sec;
   for(int pass=0;pass<2;pass++){
      ENUM_DAY_OF_WEEK day=(ENUM_DAY_OF_WEEK)((d.day_of_week+7-pass)%7);
      for(uint i=0;i<32;i++){
         datetime from,to;
         if(!SymbolInfoSessionTrade(S,day,i,from,to)) break;
         long raw=(long)to-(long)from;
         int a=(int)((long)from%86400),b=(int)((long)to%86400);
         if(pass==0){
            if(raw>=86400 || a==b) return true;
            if(a<b && sec>=a && sec<b) return true;
            if(a>b && sec>=a) return true;
         } else if(a>b && sec<b) return true;
      }
   }
   return false; // Missing session metadata = fail closed
}
bool Permissions(){
   return (bool)TerminalInfoInteger(TERMINAL_CONNECTED) &&
      (bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) &&
      (bool)MQLInfoInteger(MQL_TRADE_ALLOWED) &&
      (bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) &&
      (bool)AccountInfoInteger(ACCOUNT_TRADE_EXPERT);
}
void Observe(MqlTick &t){
   double mid=(t.ask+t.bid)/2,sp=t.ask-t.bid;
   liveSpeed=0; liveJump=0;
   if(prevMsc>0 && t.time_msc>prevMsc && atrCache>0){
      double dt=(t.time_msc-prevMsc)/1000.0;
      liveJump=MathAbs(mid-prevMid)/atrCache;
      if(dt<=1.0) liveSpeed=liveJump/MathMax(dt,0.10);
      if(liveJump>=InpMaxJumpATR || liveSpeed>=InpMaxSpeedATRPerSec)
         Cooldown(InpShockCooldownSeconds);
   }
   prevMsc=t.time_msc; prevMid=mid;
   bool shock=sp>InpMaxSpreadPoints*pt ||
      (spreadBase>0 && sp>spreadBase*InpAbnormalSpreadRatio);
   if(shock) Cooldown(InpShockCooldownSeconds);
   // Do not train the normal-spread baseline on a shock.
   if(t.time>spreadStamp && !shock){
      spreadBase=spreadBase>0 ? (1-InpSpreadEWMAAlpha)*spreadBase+InpSpreadEWMAAlpha*sp : sp;
      spreadStamp=t.time;
   }
}
bool ExecutionOK(MqlTick &t,Features &f,int dir){
   if(!Permissions())return Fail("PERMISSION_OR_CONNECTION");
   if(InpStrictBrokerSessions && !BrokerSession())return Fail("BROKER_SESSION");
   if(t.bid<=0||t.ask<=t.bid||TimeCurrent()-t.time>InpMaxTickAgeSeconds)return Fail("STALE_OR_INVALID_QUOTE");
   if(TimeCurrent()<holdUntil)return Fail("ERROR_OR_SHOCK_COOLDOWN");
   long mode=SymbolInfoInteger(S,SYMBOL_TRADE_MODE);
   if(mode==SYMBOL_TRADE_MODE_DISABLED||mode==SYMBOL_TRADE_MODE_CLOSEONLY||
      (dir>0&&mode==SYMBOL_TRADE_MODE_SHORTONLY)||(dir<0&&mode==SYMBOL_TRADE_MODE_LONGONLY))return Fail("SYMBOL_TRADE_MODE");
   double sp=t.ask-t.bid;
   if(sp>InpMaxSpreadPoints*pt || (InpMaxAbsoluteSpread>0&&sp>InpMaxAbsoluteSpread))return Fail("SPREAD_ABSOLUTE");
   if(InpMaxSpreadATR>0&&sp/f.atr>InpMaxSpreadATR)return Fail("SPREAD_ATR");
   if(spreadBase>0&&sp>spreadBase*InpAbnormalSpreadRatio)return Fail("SPREAD_ABNORMAL");
   if(liveJump>=InpMaxJumpATR||liveSpeed>=InpMaxSpeedATRPerSec)return Fail("QUOTE_JUMP_OR_SPEED");
   return true;
}

ENUM_ORDER_TYPE_FILLING Filling(){
   long flags=SymbolInfoInteger(S,SYMBOL_FILLING_MODE);
   long execution=SymbolInfoInteger(S,SYMBOL_TRADE_EXEMODE);
   if(execution==SYMBOL_TRADE_EXECUTION_REQUEST||execution==SYMBOL_TRADE_EXECUTION_INSTANT)return ORDER_FILLING_FOK;
   if((flags & SYMBOL_FILLING_FOK)!=0) return ORDER_FILLING_FOK;
   if((flags & SYMBOL_FILLING_IOC)!=0) return ORDER_FILLING_IOC;
   return ORDER_FILLING_RETURN; // OnInit rejects Market Execution without FOK/IOC
}
bool OwnSelected(){
   if(PositionGetString(POSITION_SYMBOL)!=S)return false;
   if(hedge)return (ulong)PositionGetInteger(POSITION_MAGIC)==InpMagic;
   ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   if(!HistorySelectByPosition(id)){Count("OWNERSHIP_HISTORY_UNAVAILABLE");return false;}
   bool own=false,foreign=false;
   for(int i=0;i<HistoryDealsTotal();i++){
      ulong d=HistoryDealGetTicket(i);long ty=HistoryDealGetInteger(d,DEAL_TYPE),en=HistoryDealGetInteger(d,DEAL_ENTRY);
      if((ty==DEAL_TYPE_BUY||ty==DEAL_TYPE_SELL)&&(en==DEAL_ENTRY_IN||en==DEAL_ENTRY_INOUT)){
         if((ulong)HistoryDealGetInteger(d,DEAL_MAGIC)==InpMagic)own=true;else foreign=true;
      }
   }
   if(own&&foreign){if(!uncertain)Ambiguous("Mixed netting ownership requires operator reconciliation");return false;}
   return own&&!foreign;
}

bool PositionAlive(ulong id){
   for(int i=0;i<PositionsTotal();i++) if(PositionGetTicket(i)>0 &&
      (ulong)PositionGetInteger(POSITION_IDENTIFIER)==id) return true;
   return false;
}
void RefreshLosses(){
   dirty=false;
   if(InpMaxConsecutiveLosses<=0 || !HistorySelect(epoch,TimeCurrent())) return;
   ulong ids[]; int n=0;
   for(int i=HistoryDealsTotal()-1;i>=0;i--){
      ulong d=HistoryDealGetTicket(i); long en=HistoryDealGetInteger(d,DEAL_ENTRY);
      if(HistoryDealGetString(d,DEAL_SYMBOL)!=S ||
         (en!=DEAL_ENTRY_OUT && en!=DEAL_ENTRY_OUT_BY && en!=DEAL_ENTRY_INOUT)) continue;
      ulong id=(ulong)HistoryDealGetInteger(d,DEAL_POSITION_ID);
      bool seen=false; for(int j=0;j<n;j++) if(ids[j]==id){seen=true;break;}
      if(!seen){ArrayResize(ids,n+1);ids[n++]=id;}
   }
   int streak=0;
   for(int i=0;i<n;i++){
      if(PositionAlive(ids[i]) || !HistorySelectByPosition(ids[i])) continue;
      bool own=false,foreign=false; double pnl=0;
      for(int j=0;j<HistoryDealsTotal();j++){
         ulong d=HistoryDealGetTicket(j); long en=HistoryDealGetInteger(d,DEAL_ENTRY);
         long ty=HistoryDealGetInteger(d,DEAL_TYPE);
         if(ty!=DEAL_TYPE_BUY && ty!=DEAL_TYPE_SELL) continue;
         if(en==DEAL_ENTRY_IN || en==DEAL_ENTRY_INOUT){
            if((ulong)HistoryDealGetInteger(d,DEAL_MAGIC)==InpMagic) own=true; else foreign=true;
         }
         pnl+=HistoryDealGetDouble(d,DEAL_PROFIT)+HistoryDealGetDouble(d,DEAL_SWAP)+
              HistoryDealGetDouble(d,DEAL_COMMISSION)+HistoryDealGetDouble(d,DEAL_FEE);
      }
      if(!own || foreign) continue;
      if(pnl>=0) break;
      streak++;
      if(streak>=InpMaxConsecutiveLosses){lossHalt=true;Save("lossHalt",1);break;}
   }
}
// Risk estimate includes adverse entry/exit reserve and commission; no naked positions admitted.
double RiskCash(string sym,int dir,double vol,double entry,double stop,bool entryReserve){
   double point=SymbolInfoDouble(sym,SYMBOL_POINT),p=0;
   double slip=MathMax(InpRiskSlipPoints,InpDeviationPoints)*point;
   double e=entry+(entryReserve?dir*slip:0),x=stop-dir*slip;
   if(vol<=0 || stop<=0 || !OrderCalcProfit(dir>0?ORDER_TYPE_BUY:ORDER_TYPE_SELL,sym,vol,e,x,p)) return DBL_MAX;
   return MathMax(0.0,-p)+InpCostPerLot*vol;
}
double PortfolioRisk(){
   double sum=0;
   if(OrdersTotal()>0) return DBL_MAX; // No unmodelled account-wide pending exposure
   for(int i=0;i<PositionsTotal();i++){
      if(PositionGetTicket(i)==0) return DBL_MAX;
      string sym=PositionGetString(POSITION_SYMBOL); MqlTick t;
      if(!SymbolInfoTick(sym,t) || t.bid<=0 || t.ask<=0) return DBL_MAX;
      int dir=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY?1:-1;
      double vol=PositionGetDouble(POSITION_VOLUME),sl=PositionGetDouble(POSITION_SL);
      double a=RiskCash(sym,dir,vol,PositionGetDouble(POSITION_PRICE_OPEN),sl,false);
      double b=RiskCash(sym,dir,vol,dir>0?t.bid:t.ask,sl,false);
      if(a==DBL_MAX || b==DBL_MAX) return DBL_MAX;
      sum+=MathMax(a,b); // Do not treat floating profit as risk-free collateral
   }
   return sum;
}
double VolumeFloor(double v){
   double step=SymbolInfoDouble(S,SYMBOL_VOLUME_STEP),mn=SymbolInfoDouble(S,SYMBOL_VOLUME_MIN);
   double mx=MathMin(InpMaxLot,SymbolInfoDouble(S,SYMBOL_VOLUME_MAX));
   if(step<=0 || mx<mn) return 0;
   double x=NormalizeDouble(MathFloor((MathMin(v,mx)+1e-10)/step)*step,8);
   return x+1e-9>=mn?x:0;
}
double CostOffset(double entry){
   double probe=SymbolInfoDouble(S,SYMBOL_VOLUME_MIN),p=0;
   if(!OrderCalcProfit(ORDER_TYPE_BUY,S,probe,entry,entry+ts,p) || p<=0) return DBL_MAX;
   return InpCostPerLot*probe/p*ts+MathMax(InpRiskSlipPoints,InpDeviationPoints)*pt;
}
bool Capacity(int dir,double atr){
   int count=0;
   for(int i=0;i<PositionsTotal();i++){
      ulong ticket=PositionGetTicket(i); if(ticket==0) return false;
      if(PositionGetString(POSITION_SYMBOL)!=S) continue;
      if(!hedge) return false; // Netting: never aggregate or reverse an existing symbol position
      if(!OwnSelected()) continue;
      count++;
      if(!InpAllowPyramiding || (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY?1:-1)!=dir) return false;
      double e=PositionGetDouble(POSITION_PRICE_OPEN),sl=PositionGetDouble(POSITION_SL);
      double cost=CostOffset(e); MqlTick t;
      if(cost==DBL_MAX || !SymbolInfoTick(S,t)) return false;
      if(PositionGetDouble(POSITION_PROFIT)<=InpCostPerLot*PositionGetDouble(POSITION_VOLUME) ||
         dir*(sl-e)<cost || dir*((dir>0?t.ask:t.bid)-e)<InpScaleSpacingATR*atr) return false;
   }
   return count<InpMaxPositions;
}
double Size(Signal &s,MqlTick &t){
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double factor=s.score>=InpHighScore?InpHighMultiplier:1.0;
   if(s.regime==2) factor*=InpExtremeRiskMultiplier;
   double target=equity*MathMin(InpMaxTradeRiskPct,InpBaseRiskPct*factor)/100;
   double available=equity*InpMaxOpenRiskPct/100-PortfolioRisk();
   double budget=MathMin(target,available);
   double probe=SymbolInfoDouble(S,SYMBOL_VOLUME_MIN);
   double unit=RiskCash(S,s.dir,probe,s.dir>0?t.ask:t.bid,s.sl,true)/probe;
   if(equity<=0 || budget<=0 || !MathIsValidNumber(unit) || unit<=0 || unit>=DBL_MAX/100){Count("RISK_BUDGET_OR_CALCULATION");return 0;}
   double v=VolumeFloor(budget/unit);
   double step=SymbolInfoDouble(S,SYMBOL_VOLUME_STEP);
   double minimum=MathMax(0.01,MathMax(InpMinLot,probe));
   minimum=NormalizeDouble(MathCeil((minimum-1e-10)/step)*step,8);
   if(v<minimum){
      v=minimum;
      // Minimum-lot promotion can exceed the target, never the hard trade/portfolio ceiling.
      if(v>InpMaxLot || v>SymbolInfoDouble(S,SYMBOL_VOLUME_MAX) ||
         v*unit>equity*InpMaxTradeRiskPct/100 || v*unit>available){Count("MINLOT_HARD_RISK");return 0;}
   }
   if(v*unit>equity*InpMaxTradeRiskPct/100 || v*unit>available){Count("MINLOT_HARD_RISK");return 0;}
   return v;
}
double High(int start,int count){double x=-DBL_MAX;for(int i=start;i<start+count;i++) x=MathMax(x,bars[i].high);return x;}
double Low(int start,int count){double x=DBL_MAX;for(int i=start;i<start+count;i++) x=MathMin(x,bars[i].low);return x;}
double O(int i,int d){return d*bars[i].open;}
double C(int i,int d){return d*bars[i].close;}
double H(int i,int d){return d>0?bars[i].high:-bars[i].low;}
double L(int i,int d){return d>0?bars[i].low:-bars[i].high;}
double Level(int start,int count,int d){return d>0?High(start,count):-Low(start,count);}
bool Candle(int i,int d){
   double range=H(i,d)-L(i,d);
   return range>0 && C(i,d)>O(i,d) && (C(i,d)-O(i,d))/range>=InpBodyFraction &&
      (C(i,d)-L(i,d))/range>=InpCloseLocation;
}
bool Stops(Signal &s,Features &f,MqlTick &t){
   double entry=s.dir>0?t.ask:t.bid;
   double mult=f.regime==0?InpStopATRNormal:(f.regime==1?InpStopATRExpanding:InpStopATRExtreme);
   double swing=entry-s.dir*mult*f.atr;
   if(InpUseSwingInitialStop)swing=s.dir>0?Low(1,3)-InpStructureBufferATR*f.atr:High(1,3)+InpStructureBufferATR*f.atr;
   double dist=MinDistance();
   if(s.dir>0){
      s.sl=Down(MathMin(MathMin(entry-mult*f.atr,swing),t.bid-dist));
   }else s.sl=Up(MathMax(MathMax(entry+mult*f.atr,swing),t.ask+dist));
   s.risk=s.dir*(entry-s.sl);
   if(s.risk<=0 || s.risk>InpMaxStopATR*f.atr) return false;
   double target=entry+s.dir*InpTargetR*s.risk;
   if(InpCapTPAtStructure){
      double nearest=DBL_MAX;
      for(int i=2;i<=InpStructureBars;i++){
         double level=s.dir>0?bars[i].high:bars[i].low;
         double room=s.dir*(level-entry)-InpStructureBufferATR*f.atr;
         if(room>0) nearest=MathMin(nearest,room);
      }
      if(nearest<DBL_MAX) target=entry+s.dir*MathMin(InpTargetR*s.risk,nearest);
   }
   s.tp=s.dir>0?Up(MathMax(target,t.bid+dist)):Down(MathMin(target,t.ask-dist));
   s.rr=s.dir*(s.tp-entry)/s.risk;
   return s.sl>0 && s.tp>0 && s.rr>=InpMinTargetR;
}
int Score(Signal &s,Features &f,MqlTick &t){
   int d=s.dir,v=25; // Completed price-pattern specification, not a success probability.
   if(d*(f.fast-f.slow)>0)v+=15;
   if(f.bias==d)v+=10;else if(f.bias==0)v+=5;
   if(d*(bars[1].close-bars[2].close)>=InpMomentumATR*f.atr)v+=10;
   double r=bars[1].high-bars[1].low;
   if(r>0&&(C(1,d)-O(1,d))/r>=.5)v+=10;
   if(r>0&&(C(1,d)-L(1,d))/r>=.8)v+=5;
   if(f.regime==0 || (s.module>=4&&s.module!=6))v+=5;
   double sp=t.ask-t.bid;
   if(sp<=.6*InpMaxSpreadPoints*pt && (InpMaxSpreadATR<=0||sp/f.atr<=.6*InpMaxSpreadATR))v+=10;else v+=5;
   if(s.rr>=InpTargetR-.02)v+=5;
   if(InpVolumeMode!=0&&f.hasVolume&&f.volRatio>=1)v+=5;
   return MathMin(100,v);
}

bool Pattern(int d,int module,Features &f){
   double a=f.atr,r=H(1,d)-L(1,d);if(r<=0)return false;
   double body=(C(1,d)-O(1,d))/r,wick=(MathMin(O(1,d),C(1,d))-L(1,d))/r;
   double delta=C(1,d)-C(2,d),previous=MathAbs(C(2,d)-C(3,d));
   bool aligned=d*(f.fast-f.slow)>0,normal=f.regime==0,notext=f.regime<2;
   double lev=Level(2,InpBreakoutBars,d),old=Level(3,InpBreakoutBars,d);
   double upper=High(2,InpBreakoutBars),lower=Low(2,InpBreakoutBars),width=upper-lower;
   double nearLow=d>0?lower:-upper;
   switch(module){
      case 1:return aligned&&C(1,d)>H(2,d)&&delta>InpMomentumATR*a&&MathAbs(body)>=.4&&notext;
      case 2:return aligned&&L(1,d)<=d*f.fast+InpPullbackToleranceATR*a&&L(1,d)>=d*f.slow-.4*a&&C(1,d)>d*f.fast&&C(1,d)>O(1,d)&&delta>0&&body>=InpBodyFraction&&notext;
      case 3:return delta>InpAccelerationATR*a&&delta>InpAccelerationFactor*previous&&aligned&&MathAbs(body)>=.5&&f.rangeRatio<=InpMaxRetestRangeATR;
      case 4:return C(1,d)>lev+InpBreakoutBufferATR*a&&C(1,d)-lev<=InpMaxChaseATR*a&&MathAbs(body)>=.4&&f.rangeRatio>=InpMinBreakoutRangeATR&&f.rangeRatio<=InpMaxBreakoutRangeATR&&notext;
      case 5:return C(2,d)>old+InpBreakoutBufferATR*a&&L(1,d)>=old-.35*a&&L(1,d)<=old+InpRetestToleranceATR*a&&C(1,d)>old+InpBreakoutBufferATR*a&&C(1,d)-old<=InpMaxChaseATR*a&&C(1,d)>O(1,d)&&f.rangeRatio<=InpMaxRetestRangeATR;
      case 6:return MathAbs(f.fast-f.slow)<=InpRangeFlatATR*a&&normal&&width>=InpRangeMinWidthATR*a&&width<=InpRangeMaxWidthATR*a&&L(1,d)<=nearLow+InpRangeTouchATR*a&&C(1,d)>nearLow+InpRangeRecoverATR*a&&C(1,d)>O(1,d)&&wick>=InpMinWickFraction;
      case 7:return f.regime>=1&&f.rangeRatio>=InpExpansionMinRangeATR&&f.rangeRatio<=InpExpansionMaxRangeATR&&body>=InpExpansionBody&&aligned;
      case 8:return L(1,d)<nearLow-InpBreakoutBufferATR*a&&C(1,d)>nearLow+InpBreakoutBufferATR*a&&C(1,d)>O(1,d)&&wick>=InpMinWickFraction&&f.rangeRatio<=InpExpansionMaxRangeATR;
   }
   return false;
}
bool Build(int d,int module,Features &f,MqlTick &t,Signal &s){
   if(!Pattern(d,module,f))return false;
   if(InpContextMode>=1&&f.bias==-d){stageReason="CONTEXT_M5";return false;}
   if(InpContextMode>=2&&f.bias15==-d){stageReason="CONTEXT_M15";return false;}
   double entry=d*(d>0?t.ask:t.bid);
   if(MathAbs(entry-C(1,d))>InpMaxEntryGapATR*f.atr){stageReason="ENTRY_GAP";return false;}
   s.dir=d;s.module=module;s.regime=f.regime;
   if(!Stops(s,f,t)){stageReason="STOP_OR_TARGET";return false;}
   s.score=Score(s,f,t);if(s.score<InpMinScore){stageReason="SCORE";return false;}
   return true;
}

bool KnownNoFill(uint c){
   return c==TRADE_RETCODE_REQUOTE || c==TRADE_RETCODE_PRICE_CHANGED ||
      c==TRADE_RETCODE_PRICE_OFF || c==TRADE_RETCODE_REJECT ||
      c==TRADE_RETCODE_CANCEL || c==TRADE_RETCODE_INVALID ||
      c==TRADE_RETCODE_INVALID_VOLUME || c==TRADE_RETCODE_INVALID_PRICE ||
      c==TRADE_RETCODE_INVALID_STOPS || c==TRADE_RETCODE_TRADE_DISABLED ||
      c==TRADE_RETCODE_MARKET_CLOSED || c==TRADE_RETCODE_NO_MONEY ||
      c==TRADE_RETCODE_TOO_MANY_REQUESTS ||
      c==TRADE_RETCODE_FROZEN || c==TRADE_RETCODE_INVALID_FILL ||
      c==TRADE_RETCODE_CLIENT_DISABLES_AT ||
      c==TRADE_RETCODE_SERVER_DISABLES_AT || c==TRADE_RETCODE_LIMIT_VOLUME ||
      c==TRADE_RETCODE_LIMIT_POSITIONS || c==TRADE_RETCODE_LONG_ONLY ||
      c==TRADE_RETCODE_SHORT_ONLY || c==TRADE_RETCODE_CLOSE_ONLY ||
      c==TRADE_RETCODE_HEDGE_PROHIBITED || c==TRADE_RETCODE_FIFO_CLOSE;
}
void CloseOwned(ulong ticket,string why){
   if(!PositionSelectByTicket(ticket) || !OwnSelected()) return;
   ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   double vol=PositionGetDouble(POSITION_VOLUME);
   string ck=IDKey("c",id); double pending=Load(ck,0);
   if(pending>0 && vol>=pending-1e-9) return; // Never duplicate an unresolved close
   if(pending>0) Save(ck,0); // A partial fill reduced observable exposure
   string throttle=IDKey("z",id);
   if(TimeCurrent()<(datetime)Load(throttle,0)) return;
   Save(throttle,(double)(TimeCurrent()+1));
   MqlTick t;if(!SymbolInfoTick(S,t)) return;
   MqlTradeRequest r={};MqlTradeResult out={};
   r.action=TRADE_ACTION_DEAL;r.symbol=S;r.position=ticket;r.magic=InpMagic;r.volume=vol;
   r.type=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY?ORDER_TYPE_SELL:ORDER_TYPE_BUY;
   r.price=r.type==ORDER_TYPE_SELL?t.bid:t.ask;r.deviation=(ulong)InpDeviationPoints;
   r.type_filling=Filling();r.comment="AP safety close";
   bool ok=OrderSend(r,out);
   PrintFormat("CLOSE %I64u %s sent=%d ret=%u %s",ticket,why,(int)ok,out.retcode,out.comment);
   if(out.retcode==TRADE_RETCODE_DONE || out.retcode==TRADE_RETCODE_DONE_PARTIAL){
      Save(ck,vol);return;
   }
   if(!KnownNoFill(out.retcode)){Save(ck,vol);Ambiguous("Unresolved close");}
}
void Modify(ulong ticket,double newSL,MqlTick &t){
   if(!PositionSelectByTicket(ticket)||!OwnSelected()) return;
   ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   string mk=IDKey("m",id),bk=IDKey("b",id);
   if(Load(bk,0)>0 || TimeCurrent()<(datetime)Load(mk,0)) return;
   int d=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY?1:-1;
   double old=PositionGetDouble(POSITION_SL),tp=PositionGetDouble(POSITION_TP),dist=MinDistance();
   double close=d>0?t.bid:t.ask;
   if(old<=0 || tp<=0 || d*(newSL-old)<MathMax(ts,InpTrailStepPoints*pt) ||
      d*(close-newSL)<dist || d*(tp-close)<dist) return;
   double freeze=SymbolInfoInteger(S,SYMBOL_TRADE_FREEZE_LEVEL)*pt;
   if(d*(close-old)<=freeze || d*(tp-close)<=freeze) return;
   MqlTradeRequest r={};MqlTradeResult out={};
   r.action=TRADE_ACTION_SLTP;r.position=ticket;r.symbol=S;r.magic=InpMagic;r.sl=newSL;r.tp=tp;
   Save(mk,(double)(TimeCurrent()+InpModifyIntervalSeconds));
   bool ok=OrderSend(r,out);
   if(out.retcode==TRADE_RETCODE_DONE || out.retcode==TRADE_RETCODE_NO_CHANGES) return;
   PrintFormat("MODIFY %I64u sent=%d ret=%u %s",ticket,(int)ok,out.retcode,out.comment);
   if(!KnownNoFill(out.retcode)){Save(bk,1);Ambiguous("Unresolved stop modification");}
   Cooldown(InpErrorCooldownSeconds);
}
void Manage(MqlTick &t){
   for(int i=PositionsTotal()-1;i>=0;i--){
      ulong ticket=PositionGetTicket(i);if(ticket==0 || !OwnSelected()) continue;
      ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      double e=PositionGetDouble(POSITION_PRICE_OPEN),sl=PositionGetDouble(POSITION_SL),tp=PositionGetDouble(POSITION_TP);
      double vol=PositionGetDouble(POSITION_VOLUME);
      int d=PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY?1:-1;
      if(sl<=0 || tp<=0){CloseOwned(ticket,"missing protective SL/TP");continue;}
      double cash=RiskCash(S,d,vol,e,sl,false);
      if(cash==DBL_MAX || cash>AccountInfoDouble(ACCOUNT_EQUITY)*InpMaxTradeRiskPct/100+0.01){
         CloseOwned(ticket,"post-fill hard-risk breach");continue;
      }
      if(eqHalt && InpCloseOnEquityEmergency){CloseOwned(ticket,"equity emergency");continue;}
      if(Load(IDKey("c",id),0)>0){CloseOwned(ticket,"pending residual close");continue;}
      string rk=IDKey("r",id);double R=Load(rk,0);
      if(R<=0){R=d*(e-sl);if(R<=0){CloseOwned(ticket,"original R unavailable");continue;}Save(rk,R);}
      if(InpMaxHoldingMinutes>0 && TimeCurrent()-(datetime)PositionGetInteger(POSITION_TIME)>=InpMaxHoldingMinutes*60){CloseOwned(ticket,"maximum holding duration");continue;}
      if(!InpProfitProtection || atrCache<=0) continue;
      double close=d>0?t.bid:t.ask,move=d*(close-e),next=sl,cost=CostOffset(e);
      if(cost==DBL_MAX) continue;
      double offset=cost+InpBEOffsetATR*atrCache+(t.ask-t.bid);
      if(move>=InpBETriggerR*R){
         double x=e+d*offset;next=d>0?MathMax(next,x):MathMin(next,x);
      }
      if(move>=InpLockTriggerR*R){
         double x=e+d*MathMax(offset,InpLockR*R);next=d>0?MathMax(next,x):MathMin(next,x);
      }
      if(move>=InpTrailStartR*R){
         double x=close-d*InpTrailATR*atrCache;
         if(InpSwingTrail){
            MqlRates z[];ArraySetAsSeries(z,true);
            if(CopyRates(S,PERIOD_M1,1,InpSwingTrailBars,z)==InpSwingTrailBars){
               double swing=d>0?DBL_MAX:-DBL_MAX;
               for(int j=0;j<InpSwingTrailBars;j++) swing=d>0?MathMin(swing,z[j].low):MathMax(swing,z[j].high);
               double sx=swing-d*InpStructureBufferATR*atrCache;
               x=d>0?MathMax(x,sx):MathMin(x,sx);
            }
         }
         next=d>0?MathMax(next,x):MathMin(next,x);
      }
      // Clamp toward a legal price, but NEVER below/above the already-held stop.
      next=d>0?Down(MathMin(next,t.bid-MinDistance())):Up(MathMax(next,t.ask+MinDistance()));
      if(d*(next-sl)>0) Modify(ticket,next,t);
   }
}
void EquitySafety(){
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq>peak){peak=eq;Save("peak",peak);}
   if(InpEquityEmergency && peak>0 && 100*(peak-eq)/peak>=InpEquityDDPct){
      if(!eqHalt) Print("EMERGENCY equity drawdown latch; no daily reset.");
      eqHalt=true;Save("eqHalt",1);
   }
}
bool MarginOK(MqlTradeRequest &r){
   MqlTradeCheckResult c={};
   if(!OrderCheck(r,c)){
      Log(StringFormat("OrderCheck failed ret=%u %s error=%d",c.retcode,c.comment,GetLastError()));return false;
   }
   return (c.retcode==0 || c.retcode==TRADE_RETCODE_DONE) && c.equity>0 &&
      c.margin_free>0 && 100*c.margin/c.equity<=InpMaxMarginUsagePct;
}
void Place(Signal &s,Features &f){
   for(int attempt=0;attempt<2;attempt++){
      if(TimeCurrent()-lastBar>InpMaxSignalAgeSeconds || !UserSession() || uncertain) return;
      MqlTick t;if(!SymbolInfoTick(S,t)){Audit("QUOTE_UNAVAILABLE");return;}
      if(!ExecutionOK(t,f,s.dir)){Audit(stageReason);return;}
      if(!Capacity(s.dir,f.atr)){Audit("POSITION_CAPACITY");return;}
      Signal refreshed;
      if(!Build(s.dir,s.module,f,t,refreshed)){Audit("REFRESH_"+stageReason);return;}
      s=refreshed;double vol=Size(s,t);if(vol<=0){Audit("RISK_OR_MINIMUM_VOLUME");return;}
      MqlTradeRequest r={};MqlTradeResult out={};
      r.action=TRADE_ACTION_DEAL;r.symbol=S;r.magic=InpMagic;r.volume=vol;
      r.type=s.dir>0?ORDER_TYPE_BUY:ORDER_TYPE_SELL;r.price=s.dir>0?t.ask:t.bid;
      r.sl=s.sl;r.tp=s.tp;r.deviation=(ulong)InpDeviationPoints;r.type_filling=Filling();
      r.comment=StringFormat("AP M%d R%d S%d",s.module,s.regime,s.score);
      if(!MarginOK(r)){Audit("ORDERCHECK_OR_MARGIN");return;}
      Audit("ORDER_SUBMITTED",s.module,s.dir,s.score);
      bool ok=OrderSend(r,out);
      Audit(StringFormat("ORDER_RETCODE_%u",out.retcode),s.module,s.dir,s.score);
      PrintFormat("ENTRY bar=%s module=%d regime=%d score=%d vol=%.8f SL=%.*f TP=%.*f sent=%d ret=%u deal=%I64u order=%I64u %s",
         TimeToString(lastBar),s.module,s.regime,s.score,vol,digits,s.sl,digits,s.tp,(int)ok,out.retcode,out.deal,out.order,out.comment);
      if(out.retcode==TRADE_RETCODE_DONE || out.retcode==TRADE_RETCODE_DONE_PARTIAL){
         // A successful return alone is insufficient evidence of visible protected exposure.
         Audit("ORDER_ACCEPTED",s.module,s.dir,s.score);
         bool reconciled=false;ulong newID=0;
         if(out.deal>0 && HistoryDealSelect(out.deal)){
            ulong id=(ulong)HistoryDealGetInteger(out.deal,DEAL_POSITION_ID);newID=id;
            if(id>0 && PositionAlive(id)) reconciled=true;
            else if(id>0 && HistorySelectByPosition(id)){
               double balance=0;
               for(int j=0;j<HistoryDealsTotal();j++){
                  ulong dd=HistoryDealGetTicket(j);
                  long en=HistoryDealGetInteger(dd,DEAL_ENTRY);
                  if(en==DEAL_ENTRY_IN) balance+=HistoryDealGetDouble(dd,DEAL_VOLUME);
                  if(en==DEAL_ENTRY_OUT || en==DEAL_ENTRY_OUT_BY) balance-=HistoryDealGetDouble(dd,DEAL_VOLUME);
               }
               reconciled=MathAbs(balance)<1e-8; // Already fully closed by SL/TP
            }
         }
         if(!reconciled) Ambiguous("Successful entry not yet reconciled in terminal state");
         MqlTick latest;if(SymbolInfoTick(S,latest)) Manage(latest);
         if(newID>0 && PortfolioRisk()>AccountInfoDouble(ACCOUNT_EQUITY)*InpMaxOpenRiskPct/100+0.01){
            for(int i=PositionsTotal()-1;i>=0;i--){
               ulong ticket=PositionGetTicket(i);
               if(ticket>0 && (ulong)PositionGetInteger(POSITION_IDENTIFIER)==newID){
                  CloseOwned(ticket,"post-fill portfolio-risk breach");break;
               }
            }
         }
         return;
      }
      bool retry=out.retcode==TRADE_RETCODE_REQUOTE || out.retcode==TRADE_RETCODE_PRICE_CHANGED;
      if(retry && attempt==0 && InpSafeRequoteRetry) continue;
      Audit("ORDER_REJECTED_OR_UNRESOLVED",s.module,s.dir,s.score);
      if(!KnownNoFill(out.retcode)) Ambiguous("Unresolved entry; NEVER blindly resend");
      Cooldown(InpErrorCooldownSeconds);return;
   }
}
bool ClaimBar(datetime bar){
   if(Tester()) return true;
   string key=Key("bar");
   if(!GlobalVariableCheck(key)) GlobalVariableSet(key,0);
   double previous=GlobalVariableGet(key);
   if(previous>=(double)bar) return false;
   return GlobalVariableSetOnCondition(key,(double)bar,previous);
}
void Evaluate(){
   Count("NEW_M1_BAR");
   Features f;if(!ReadFeatures(f)){Audit(stageReason);return;}
   MqlTick t;if(!SymbolInfoTick(S,t)){Audit("QUOTE_UNAVAILABLE");return;}
   Signal best;best.score=-1;bool anyRaw=false;
   for(int m=1;m<=8;m++)if(ModuleEnabled(m)){
      for(int d=-1;d<=1;d+=2){
         if(!Pattern(d,m,f))continue;
         anyRaw=true;rawCounts[m-1]++;Audit("RAW_PATTERN",m,d);
         Signal x;stageReason="PATTERN";
         if(!Build(d,m,f,t,x)){Audit(stageReason,m,d);continue;}
         Audit("SIGNAL_VALID",m,d,x.score);
         if(x.score>best.score)best=x;
      }
   }
   if(!anyRaw){Audit("NO_ENABLED_PATTERN");return;}
   if(best.score<0){Audit("ALL_CANDIDATES_FILTERED");return;}
   // In audit mode observe price setups even with entry switches or latches active.
   if(!InpEnableEntries){Audit("ENTRIES_DISABLED",best.module,best.dir,best.score);return;}
   if(eqHalt||lossHalt||uncertain){Audit("SAFETY_LATCH");return;}
   if(!UserSession()){Audit("USER_SESSION");return;}
   if(TimeCurrent()-lastBar>InpMaxSignalAgeSeconds){Audit("SIGNAL_STALE");return;}
   if(!ExecutionOK(t,f,best.dir)){Audit(stageReason);return;}
   Place(best,f);
}

bool Validate(){
   if(InpContextMode<0||InpContextMode>2||InpVolumeMode<0||InpVolumeMode>2||
      InpSummaryEveryBars<1||InpMaxHoldingMinutes<0||InpMaxAbsoluteSpread<0||
      InpAccelerationATR<=0||InpAccelerationFactor<=0||InpRangeFlatATR<0||
      InpRangeMinWidthATR<=0||InpRangeMaxWidthATR<InpRangeMinWidthATR||
      InpRangeTouchATR<0||InpRangeRecoverATR<0||InpMinWickFraction<0||InpMinWickFraction>1||
      InpExpansionMinRangeATR<=0||InpExpansionMaxRangeATR<InpExpansionMinRangeATR||
      InpExpansionBody<=0||InpExpansionBody>1||InpMaxEntryGapATR<=0)return false;
   if(InpMagic==0 || InpFastM1<2 || InpSlowM1<=InpFastM1 || InpFastM5<2 || InpSlowM5<=InpFastM5 ||
      InpATRPeriod<2 || InpATRBaseline<2 || InpVolumeBars<2 || InpBreakoutBars<2 ||
      InpStructureBars<InpBreakoutBars+2 || InpSlopeBars<1 || InpSwingTrailBars<1) return false;
   if(InpMinScore<0 || InpHighScore<InpMinScore || InpHighScore>100 || InpBaseRiskPct<=0 ||
      InpMaxTradeRiskPct<InpBaseRiskPct || InpMaxOpenRiskPct<InpMaxTradeRiskPct ||
      InpHighMultiplier<1 || InpExtremeRiskMultiplier<=0 || InpExtremeRiskMultiplier>1 ||
      InpMinLot<0.01 || InpMaxLot<InpMinLot || InpMaxPositions<1 || InpCostPerLot<0 ||
      InpRiskSlipPoints<0 || InpDeviationPoints<0 || InpMaxMarginUsagePct<=0 || InpMaxMarginUsagePct>100) return false;
   if(InpExpandATR<=0 || InpExtremeATR<=InpExpandATR || InpExpandRange<=0 ||
      InpExtremeRange<=InpExpandRange || InpBodyFraction<=0 || InpBodyFraction>1 ||
      InpCloseLocation<0.5 || InpCloseLocation>1 || InpVolumeExpansion<1 ||
      InpStopATRNormal<=0 || InpStopATRExpanding<=0 || InpStopATRExtreme<=0 ||
      InpMaxStopATR<=0 || InpTargetR<InpMinTargetR || InpMinTargetR<=0 ||
      InpMaxBreakoutRangeATR<InpMinBreakoutRangeATR || InpMaxRetestRangeATR<=0) return false;
   if(InpMaxSpreadPoints<=0 || InpMaxSpreadATR<0 || InpAbnormalSpreadRatio<=1 ||
      InpSpreadEWMAAlpha<=0 || InpSpreadEWMAAlpha>1 || InpMaxJumpATR<=0 ||
      InpMaxSpeedATRPerSec<=0 || InpMaxTickAgeSeconds<1 || InpMaxSignalAgeSeconds<1 ||
      InpErrorCooldownSeconds<0 || InpShockCooldownSeconds<0 || InpModifyIntervalSeconds<1 ||
      InpTrailStepPoints<0 || InpStopSafetyPoints<0 || InpBETriggerR<=0 ||
      InpBEOffsetATR<0 || InpLockTriggerR<InpBETriggerR || InpLockR<0 ||
      InpTrailStartR<InpBETriggerR || InpTrailATR<=0 || InpEquityDDPct<=0 ||
      InpEquityDDPct>=100 || InpMaxConsecutiveLosses<0 || InpSlopeATR<0 ||
      InpPullbackToleranceATR<0 || InpMomentumATR<0 || InpBreakoutBufferATR<0 ||
      InpRetestToleranceATR<0 || InpMaxChaseATR<=0 || InpMinBreakoutRangeATR<=0 ||
      InpStructureBufferATR<0 || InpScaleSpacingATR<0) return false;
   for(int i=0;i<6;i++) if(sessions[i]<0) return false;
   return true;
}
int OnInit(){
   S=InpSymbol==""?_Symbol:InpSymbol;
   // OnTick belongs to the attached chart. Reject mismatches rather than miss gold ticks.
   if(S!=_Symbol || _Period!=PERIOD_M1 || !SymbolSelect(S,true)){
      Print("Attach to the exact configured symbol's M1 chart.");return INIT_PARAMETERS_INCORRECT;
   }
   sessions[0]=ParseTime(InpAsiaStart);sessions[1]=ParseTime(InpAsiaEnd);
   sessions[2]=ParseTime(InpLondonStart);sessions[3]=ParseTime(InpLondonEnd);
   sessions[4]=ParseTime(InpNewYorkStart);sessions[5]=ParseTime(InpNewYorkEnd);
   if(!Validate()) return INIT_PARAMETERS_INCORRECT;
   pt=SymbolInfoDouble(S,SYMBOL_POINT);ts=SymbolInfoDouble(S,SYMBOL_TRADE_TICK_SIZE);
   digits=(int)SymbolInfoInteger(S,SYMBOL_DIGITS);
   if(pt<=0 || ts<=0 || SymbolInfoDouble(S,SYMBOL_VOLUME_STEP)<=0 ||
      SymbolInfoDouble(S,SYMBOL_VOLUME_MIN)<=0 || SymbolInfoDouble(S,SYMBOL_VOLUME_MAX)<InpMinLot) return INIT_FAILED;
   long orderMode=SymbolInfoInteger(S,SYMBOL_ORDER_MODE),fill=SymbolInfoInteger(S,SYMBOL_FILLING_MODE);
   if((orderMode & SYMBOL_ORDER_MARKET)==0 || (orderMode & SYMBOL_ORDER_SL)==0 ||
      (orderMode & SYMBOL_ORDER_TP)==0) return INIT_FAILED;
   if((SymbolInfoInteger(S,SYMBOL_TRADE_EXEMODE)==SYMBOL_TRADE_EXECUTION_MARKET ||
       SymbolInfoInteger(S,SYMBOL_TRADE_EXEMODE)==SYMBOL_TRADE_EXECUTION_EXCHANGE) &&
      (fill & (SYMBOL_FILLING_FOK|SYMBOL_FILLING_IOC))==0) return INIT_FAILED;
   hedge=AccountInfoInteger(ACCOUNT_MARGIN_MODE)==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING;
   K=StringFormat("AR2.%I64d.%I64u.%s",AccountInfoInteger(ACCOUNT_LOGIN),InpMagic,S);
   if(StringLen(K)>36){Print("State key too long: use shorter symbol/magic combination.");return INIT_FAILED;}
   hFast=iMA(S,PERIOD_M1,InpFastM1,0,MODE_EMA,PRICE_CLOSE);
   hSlow=iMA(S,PERIOD_M1,InpSlowM1,0,MODE_EMA,PRICE_CLOSE);
   hATR=iATR(S,PERIOD_M1,InpATRPeriod);
   hHFast=iMA(S,PERIOD_M5,InpFastM5,0,MODE_EMA,PRICE_CLOSE);
   hHSlow=iMA(S,PERIOD_M5,InpSlowM5,0,MODE_EMA,PRICE_CLOSE);
   hHATR=iATR(S,PERIOD_M5,InpATRPeriod);
   h15Fast=iMA(S,PERIOD_M15,InpFastM5,0,MODE_EMA,PRICE_CLOSE);
   h15Slow=iMA(S,PERIOD_M15,InpSlowM5,0,MODE_EMA,PRICE_CLOSE);
   h15ATR=iATR(S,PERIOD_M15,InpATRPeriod);
   if(hFast==INVALID_HANDLE || hSlow==INVALID_HANDLE || hATR==INVALID_HANDLE ||
      hHFast==INVALID_HANDLE || hHSlow==INVALID_HANDLE || hHATR==INVALID_HANDLE ||
      h15Fast==INVALID_HANDLE || h15Slow==INVALID_HANDLE || h15ATR==INVALID_HANDLE) return INIT_FAILED;
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);
   if(InpResetSafetyState){
      Save("peak",eq);Save("eqHalt",0);Save("lossHalt",0);Save("uncertain",0);Save("epoch",(double)TimeCurrent());
      for(int i=0;i<PositionsTotal();i++) if(PositionGetTicket(i)>0 && OwnSelected()){
         ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
         Save(IDKey("c",id),0);Save(IDKey("b",id),0);
      }
   }
   peak=Load("peak",eq);eqHalt=Load("eqHalt",0)>0;lossHalt=Load("lossHalt",0)>0;
   uncertain=Load("uncertain",0)>0;epoch=(datetime)Load("epoch",(double)TimeCurrent());
   Save("epoch",(double)epoch);Save("peak",peak);
   lastBar=iTime(S,PERIOD_M1,0); // No retroactive signal at attachment/restart
   Buf(hATR,1,atrCache);
   Log(StringFormat("Initialized %s %s; equity=%.2f contract=%.2f point=%g tick=%g lossTickValue=%g",
      S,hedge?"hedging":"netting",eq,SymbolInfoDouble(S,SYMBOL_TRADE_CONTRACT_SIZE),pt,ts,
      SymbolInfoDouble(S,SYMBOL_TRADE_TICK_VALUE_LOSS)));
   if(InpDiagnosticCSV){
      string name=StringFormat("AurumResearch_%I64d_%I64u_%s_%I64d.csv",AccountInfoInteger(ACCOUNT_LOGIN),InpMagic,S,(long)TimeCurrent());
      diagFile=FileOpen(name,FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_SHARE_READ,',');
      if(diagFile==INVALID_HANDLE)Print("AR2 CSV open failed error=",GetLastError());
      else FileWrite(diagFile,"server_time","signal_bar","event","module","direction","score","spread_price","atr_price","equity","eq_halt","loss_halt","uncertain");
   }
   Print("RESEARCH BUILD: no module passed cost-adjusted validation. Entries enabled=",InpEnableEntries,
      "; audit=",InpAuditWhenDisabled,"; volume mode=",InpVolumeMode);
   // Reconcile already-completed original lifecycles after an orderly or abrupt restart.
   if(HistorySelect(epoch,TimeCurrent())){
      for(int i=0;i<HistoryDealsTotal();i++){
         ulong d=HistoryDealGetTicket(i);long en=HistoryDealGetInteger(d,DEAL_ENTRY);
         if(HistoryDealGetString(d,DEAL_SYMBOL)==S&&(en==DEAL_ENTRY_OUT||en==DEAL_ENTRY_OUT_BY))
            QueueClosed((ulong)HistoryDealGetInteger(d,DEAL_POSITION_ID));
      }
   }
   return INIT_SUCCEEDED;
}
void OnTick(){
   MqlTick t;if(!SymbolInfoTick(S,t) || t.bid<=0 || t.ask<=0) return;
   double a;if(Buf(hATR,1,a) && a>0) atrCache=a;
   Observe(t);EquitySafety();PollClosed();Manage(t); // Management does not depend on entry/session gates
   if(dirty) RefreshLosses();
   datetime bar=iTime(S,PERIOD_M1,0);
   if(bar<=0 || bar==lastBar) return;
   lastBar=bar;
   if(ClaimBar(bar)){
      if(InpEnableEntries||InpAuditWhenDisabled)Evaluate();
      else Audit("ENTRIES_AND_AUDIT_DISABLED");
      static int observed=0;observed++;if(observed%InpSummaryEveryBars==0)Summary();
   } // One candidate/attempt chain per closed-bar signal
}
void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result){
   if(trans.type==TRADE_TRANSACTION_DEAL_ADD || trans.type==TRADE_TRANSACTION_POSITION){
      dirty=true;
      if(trans.type==TRADE_TRANSACTION_DEAL_ADD && HistoryDealSelect(trans.deal)){
         long en=HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
         if(HistoryDealGetString(trans.deal,DEAL_SYMBOL)==S && (en==DEAL_ENTRY_OUT||en==DEAL_ENTRY_OUT_BY))
            QueueClosed((ulong)HistoryDealGetInteger(trans.deal,DEAL_POSITION_ID));
      }
      MqlTick t;
      if(SymbolInfoTick(S,t) && t.bid>0 && t.ask>0){EquitySafety();Manage(t);}
   }
   // Event ordering is not assumed: OnTick and post-send audits remain active too.
}
void OnDeinit(const int reason){
   if(hFast!=INVALID_HANDLE) IndicatorRelease(hFast);
   if(hSlow!=INVALID_HANDLE) IndicatorRelease(hSlow);
   if(hATR!=INVALID_HANDLE) IndicatorRelease(hATR);
   if(hHFast!=INVALID_HANDLE) IndicatorRelease(hHFast);
   if(hHSlow!=INVALID_HANDLE) IndicatorRelease(hHSlow);
   if(hHATR!=INVALID_HANDLE) IndicatorRelease(hHATR);
   if(h15Fast!=INVALID_HANDLE)IndicatorRelease(h15Fast);
   if(h15Slow!=INVALID_HANDLE)IndicatorRelease(h15Slow);
   if(h15ATR!=INVALID_HANDLE)IndicatorRelease(h15ATR);
   Summary();if(diagFile!=INVALID_HANDLE)FileClose(diagFile);
   if(!Tester()) GlobalVariablesFlush();
}
