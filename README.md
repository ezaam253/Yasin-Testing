// AurumPulse.mq5 -- research baseline; no performance claims.
#property strict
#property version "1.00"

input group "Identity and switches"
input string InpSymbol="";
input ulong  InpMagic=26011001;
input bool   InpEnableEntries=true;
input bool   InpResetSafetyState=false;
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
input bool   InpPullback=true;
input bool   InpBreakout=true;
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
input int    InpMinScore=70;
input int    InpHighScore=85;

input group "Sizing; percentages of equity; costs in account currency"
input double InpBaseRiskPct=0.20;
input double InpHighMultiplier=1.25;
input double InpExtremeRiskMultiplier=0.50;
input double InpMaxTradeRiskPct=0.35;
input double InpMinLot=0.01;
input double InpMaxLot=1.00;
input double InpMaxOpenRiskPct=1.00;
input int    InpMaxPositions=3;
input bool   InpAllowPyramiding=false;
input double InpScaleSpacingATR=0.25;
input double InpMaxMarginUsagePct=25.0;
input double InpCostPerLot=7.0;
input int    InpRiskSlipPoints=30;

input group "Initial stops and targets"
input double InpStopATRNormal=1.20;
input double InpStopATRExpanding=1.50;
input double InpStopATRExtreme=1.80;
input double InpStructureBufferATR=0.12;
input double InpMaxStopATR=3.50;
input double InpTargetR=1.50;
input double InpMinTargetR=1.10;
input bool   InpCapTPAtStructure=true;
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
input double InpMaxSpreadATR=0.18;
input double InpAbnormalSpreadRatio=3.00;
input double InpSpreadEWMAAlpha=0.05;
input int    InpDeviationPoints=30;
input double InpMaxJumpATR=0.80;
input double InpMaxSpeedATRPerSec=2.50;
input int    InpMaxTickAgeSeconds=5;
input int    InpMaxSignalAgeSeconds=10;
input int    InpErrorCooldownSeconds=10;
input int    InpShockCooldownSeconds=5;
input bool   InpSafeRequoteRetry=true;

input group "Emergency safety; NOT daily trading limits"
input bool   InpEquityEmergency=false;
input double InpEquityDDPct=10.0;
input bool   InpCloseOnEquityEmergency=true;
input int    InpMaxConsecutiveLosses=0;

struct Features {
   double atr,atrRatio,rangeRatio,volRatio,vol2,fast,slow;
   int bias,regime;
};
struct Signal {
   int dir,module,score,regime;
   double sl,tp,risk,rr;
};

string S,K;
double pt,ts,spreadBase=0,atrCache=0,peak=0;
int digits;
int hFast=INVALID_HANDLE,hSlow=INVALID_HANDLE,hATR=INVALID_HANDLE;
int hHFast=INVALID_HANDLE,hHSlow=INVALID_HANDLE,hHATR=INVALID_HANDLE;
int sessions[6];
bool hedge=false,eqHalt=false,lossHalt=false,uncertain=false,dirty=true;
datetime lastBar=0,holdUntil=0,spreadStamp=0,epoch=0;
long prevMsc=0;
double prevMid=0,liveSpeed=0,liveJump=0;
MqlRates bars[];
string testKeys[];
double testValues[];

bool Tester(){return (bool)MQLInfoInteger(MQL_TESTER);}

void Log(string text){
   if(InpVerbose) Print("AurumPulse: ",text);
}

string Key(string x){return K+"."+x;}

double Load(string x,double fallback=0){
   if(Tester()){
      for(int i=0;i<ArraySize(testKeys);i++)
         if(testKeys[i]==x) return testValues[i];
      return fallback;
   }
   if(!GlobalVariableCheck(Key(x))) return fallback;
   return GlobalVariableGet(Key(x));
}

void Save(string x,double v){
   if(Tester()){
      int n=ArraySize(testKeys);
      for(int i=0;i<n;i++)
         if(testKeys[i]==x){testValues[i]=v;return;}
      ArrayResize(testKeys,n+1);
      ArrayResize(testValues,n+1);
      testKeys[n]=x;
      testValues[n]=v;
      return;
   }
   if(GlobalVariableSet(Key(x),v)==0){
      uncertain=true;
      Print("SAFETY: persistent-state write failed: ",Key(x));
   }
}

string IDKey(string tag,ulong id){
   return tag+StringFormat("%I64u",id);
}

void Ambiguous(string reason){
   uncertain=true;
   Save("uncertain",1);
   Print("SAFETY LATCH: ",reason,
         "; reconcile orders/deals/positions before explicit reset.");
}

void Cooldown(int seconds){
   holdUntil=(datetime)MathMax((double)holdUntil,
                              (double)(TimeCurrent()+seconds));
}

double Down(double p){
   return NormalizeDouble(MathFloor(p/ts+1e-9)*ts,digits);
}

double Up(double p){
   return NormalizeDouble(MathCeil(p/ts-1e-9)*ts,digits);
}

double MinDistance(){
   long a=SymbolInfoInteger(S,SYMBOL_TRADE_STOPS_LEVEL);
   long b=SymbolInfoInteger(S,SYMBOL_TRADE_FREEZE_LEVEL);
   return MathMax((double)a,(double)b)*pt
          +InpStopSafetyPoints*pt+ts;
}

bool Buf(int handle,int shift,double &v){
   double a[1];
   if(handle==INVALID_HANDLE ||
      BarsCalculated(handle)<=shift ||
      CopyBuffer(handle,0,shift,1,a)!=1 ||
      !MathIsValidNumber(a[0])) return false;
   v=a[0];
   return true;
}

bool ReadFeatures(Features &f){
   int need=MathMax(InpStructureBars+5,
            MathMax(InpBreakoutBars+5,
            MathMax(InpVolumeBars+4,InpSwingTrailBars+3)));

   ArraySetAsSeries(bars,true);
   if(CopyRates(S,PERIOD_M1,0,need,bars)!=need) return false;

   double hf,hs,old,ha,sum=0,v;
   if(!Buf(hFast,1,f.fast) ||
      !Buf(hSlow,1,f.slow) ||
      !Buf(hATR,1,f.atr) ||
      !Buf(hHFast,1,hf) ||
      !Buf(hHSlow,1,hs) ||
      !Buf(hHFast,1+InpSlopeBars,old) ||
      !Buf(hHATR,1,ha)) return false;

   if(f.atr<=0 || ha<=0) return false;

   for(int i=2;i<=InpATRBaseline+1;i++){
      if(!Buf(hATR,i,v)) return false;
      sum+=v;
   }
   if(sum<=0) return false;

   f.atrRatio=f.atr/(sum/InpATRBaseline);
   f.rangeRatio=(bars[1].high-bars[1].low)/f.atr;

   sum=0;
   for(int i=3;i<3+InpVolumeBars;i++)
      sum+=(double)bars[i].tick_volume;

   if(sum<=0) return false;
   f.volRatio=(double)bars[1].tick_volume/(sum/InpVolumeBars);
   f.vol2=(double)bars[2].tick_volume/(sum/InpVolumeBars);

   double slope=(hf-old)/ha;
   f.bias=(hf>hs && slope>=InpSlopeATR)?1:
          ((hf<hs && slope<=-InpSlopeATR)?-1:0);

   f.regime=0;
   if(f.atrRatio>=InpExpandATR ||
      (f.rangeRatio>=InpExpandRange &&
       f.volRatio>=InpVolumeExpansion)) f.regime=1;

   if(f.atrRatio>=InpExtremeATR ||
      f.rangeRatio>=InpExtremeRange ||
      (spreadBase>0 &&
       (SymbolInfoInteger(S,SYMBOL_SPREAD)*pt)>
       spreadBase*InpAbnormalSpreadRatio) ||
      liveSpeed>=InpMaxSpeedATRPerSec ||
      liveJump>=InpMaxJumpATR) f.regime=2;

   atrCache=f.atr;
   return true;
}

int ParseTime(string text){
   string p[];
   if(StringLen(text)!=5 ||
      StringGetCharacter(text,2)!=58 ||
      StringSplit(text,58,p)!=2) return -1;

   for(int i=0;i<5;i++)
      if(i!=2 &&
         (StringGetCharacter(text,i)<48 ||
          StringGetCharacter(text,i)>57)) return -1;

   int h=(int)StringToInteger(p[0]);
   int m=(int)StringToInteger(p[1]);
   if(h>23 || m>59) return -1;
   return h*60+m;
}

bool InWindow(int now,int a,int b){
   if(a==b) return true; // Equal times mean 24 hours.
   return a<b ? (now>=a && now<b) : (now>=a || now<b);
}

bool UserSession(){
   MqlDateTime d;
   TimeToStruct(TimeCurrent(),d);
   int m=d.hour*60+d.min;
   return
      (InpAsia && InWindow(m,sessions[0],sessions[1])) ||
      (InpLondon && InWindow(m,sessions[2],sessions[3])) ||
      (InpNewYork && InWindow(m,sessions[4],sessions[5]));
}

bool BrokerSession(){
   MqlDateTime d;
   TimeToStruct(TimeCurrent(),d);
   int sec=d.hour*3600+d.min*60+d.sec;

   for(int pass=0;pass<2;pass++){
      ENUM_DAY_OF_WEEK day=
         (ENUM_DAY_OF_WEEK)((d.day_of_week+7-pass)%7);

      for(uint i=0;i<32;i++){
         datetime from,to;
         if(!SymbolInfoSessionTrade(S,day,i,from,to)) break;

         long raw=(long)to-(long)from;
         int a=(int)((long)from%86400);
         int b=(int)((long)to%86400);

         if(pass==0){
            if(raw>=86400 || a==b) return true;
            if(a<b && sec>=a && sec<b) return true;
            if(a>b && sec>=a) return true;
         }
         else if(a>b && sec<b) return true;
      }
   }
   return false; // Missing session metadata: fail closed.
}

bool Permissions(){
   return
      (bool)TerminalInfoInteger(TERMINAL_CONNECTED) &&
      (bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) &&
      (bool)MQLInfoInteger(MQL_TRADE_ALLOWED) &&
      (bool)AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) &&
      (bool)AccountInfoInteger(ACCOUNT_TRADE_EXPERT);
}

void Observe(MqlTick &t){
   double mid=(t.ask+t.bid)/2;
   double sp=t.ask-t.bid;
   liveSpeed=0;
   liveJump=0;

   if(prevMsc>0 && t.time_msc>prevMsc && atrCache>0){
      double dt=(t.time_msc-prevMsc)/1000.0;
      liveJump=MathAbs(mid-prevMid)/atrCache;
      if(dt<=1.0)
         liveSpeed=liveJump/MathMax(dt,0.10);

      if(liveJump>=InpMaxJumpATR ||
         liveSpeed>=InpMaxSpeedATRPerSec)
         Cooldown(InpShockCooldownSeconds);
   }

   prevMsc=t.time_msc;
   prevMid=mid;

   bool shock=sp>InpMaxSpreadPoints*pt ||
      (spreadBase>0 &&
       sp>spreadBase*InpAbnormalSpreadRatio);

   if(shock) Cooldown(InpShockCooldownSeconds);

   // Do not train the normal-spread baseline on shock spreads.
   if(t.time>spreadStamp && !shock){
      spreadBase=spreadBase>0 ?
         (1-InpSpreadEWMAAlpha)*spreadBase+
         InpSpreadEWMAAlpha*sp : sp;
      spreadStamp=t.time;
   }
}

bool ExecutionOK(MqlTick &t,Features &f,int dir){
   if(!Permissions() ||
      !BrokerSession() ||
      t.bid<=0 || t.ask<=t.bid ||
      TimeCurrent()-t.time>InpMaxTickAgeSeconds ||
      TimeCurrent()<holdUntil) return false;

   long mode=SymbolInfoInteger(S,SYMBOL_TRADE_MODE);
   if(mode==SYMBOL_TRADE_MODE_DISABLED ||
      mode==SYMBOL_TRADE_MODE_CLOSEONLY ||
      (dir>0 && mode==SYMBOL_TRADE_MODE_SHORTONLY) ||
      (dir<0 && mode==SYMBOL_TRADE_MODE_LONGONLY))
      return false;

   double sp=t.ask-t.bid;
   if(sp>InpMaxSpreadPoints*pt ||
      (InpMaxSpreadATR>0 && sp/f.atr>InpMaxSpreadATR) ||
      (spreadBase>0 &&
       sp>spreadBase*InpAbnormalSpreadRatio) ||
      liveJump>=InpMaxJumpATR ||
      liveSpeed>=InpMaxSpeedATRPerSec) return false;

   return true;
}

ENUM_ORDER_TYPE_FILLING Filling(){
   long flags=SymbolInfoInteger(S,SYMBOL_FILLING_MODE);
   if((flags & SYMBOL_FILLING_FOK)!=0)
      return ORDER_FILLING_FOK;
   if((flags & SYMBOL_FILLING_IOC)!=0)
      return ORDER_FILLING_IOC;
   return ORDER_FILLING_RETURN;
}

bool OwnSelected(){
   if(PositionGetString(POSITION_SYMBOL)!=S ||
      (ulong)PositionGetInteger(POSITION_MAGIC)!=InpMagic)
      return false;

   if(hedge) return true;

   ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   if(!HistorySelectByPosition(id)) return false;

   for(int j=0;j<HistoryDealsTotal();j++){
      ulong d=HistoryDealGetTicket(j);
      long en=HistoryDealGetInteger(d,DEAL_ENTRY);
      long ty=HistoryDealGetInteger(d,DEAL_TYPE);

      if((ty==DEAL_TYPE_BUY || ty==DEAL_TYPE_SELL) &&
         (en==DEAL_ENTRY_IN || en==DEAL_ENTRY_INOUT) &&
         (ulong)HistoryDealGetInteger(d,DEAL_MAGIC)!=InpMagic){
         if(!uncertain)
            Ambiguous("Mixed netting ownership; no safe "
                      "per-EA subposition exists");
         return false;
      }
   }
   return true;
}

bool PositionAlive(ulong id){
   for(int i=0;i<PositionsTotal();i++)
      if(PositionGetTicket(i)>0 &&
         (ulong)PositionGetInteger(POSITION_IDENTIFIER)==id)
         return true;
   return false;
}

void RefreshLosses(){
   dirty=false;
   if(InpMaxConsecutiveLosses<=0 ||
      !HistorySelect(epoch,TimeCurrent())) return;

   ulong ids[];
   int n=0;

   for(int i=HistoryDealsTotal()-1;i>=0;i--){
      ulong d=HistoryDealGetTicket(i);
      long en=HistoryDealGetInteger(d,DEAL_ENTRY);

      if(HistoryDealGetString(d,DEAL_SYMBOL)!=S ||
         (en!=DEAL_ENTRY_OUT &&
          en!=DEAL_ENTRY_OUT_BY &&
          en!=DEAL_ENTRY_INOUT)) continue;

      ulong id=(ulong)HistoryDealGetInteger(d,DEAL_POSITION_ID);
      bool seen=false;
      for(int j=0;j<n;j++)
         if(ids[j]==id){seen=true;break;}

      if(!seen){
         ArrayResize(ids,n+1);
         ids[n++]=id;
      }
   }

   int streak=0;

   for(int i=0;i<n;i++){
      if(PositionAlive(ids[i]) ||
         !HistorySelectByPosition(ids[i])) continue;

      bool own=false,foreign=false;
      double pnl=0;

      for(int j=0;j<HistoryDealsTotal();j++){
         ulong d=HistoryDealGetTicket(j);
         long en=HistoryDealGetInteger(d,DEAL_ENTRY);
         long ty=HistoryDealGetInteger(d,DEAL_TYPE);

         if(ty!=DEAL_TYPE_BUY && ty!=DEAL_TYPE_SELL) continue;

         if(en==DEAL_ENTRY_IN || en==DEAL_ENTRY_INOUT){
            if((ulong)HistoryDealGetInteger(d,DEAL_MAGIC)==InpMagic)
               own=true;
            else
               foreign=true;
         }

         pnl+=HistoryDealGetDouble(d,DEAL_PROFIT)
              +HistoryDealGetDouble(d,DEAL_SWAP)
              +HistoryDealGetDouble(d,DEAL_COMMISSION)
              +HistoryDealGetDouble(d,DEAL_FEE);
      }

      if(!own || foreign) continue;
      if(pnl>=0) break;

      streak++;
      if(streak>=InpMaxConsecutiveLosses){
         lossHalt=true;
         Save("lossHalt",1);
         break;
      }
   }
}

double RiskCash(string sym,int dir,double vol,
                double entry,double stop,bool entryReserve){
   double point=SymbolInfoDouble(sym,SYMBOL_POINT),p=0;
   double slip=MathMax(InpRiskSlipPoints,InpDeviationPoints)*point;
   double e=entry+(entryReserve?dir*slip:0);
   double x=stop-dir*slip;

   if(vol<=0 || stop<=0 ||
      !OrderCalcProfit(
         dir>0?ORDER_TYPE_BUY:ORDER_TYPE_SELL,
         sym,vol,e,x,p)) return DBL_MAX;

   return MathMax(0.0,-p)+InpCostPerLot*vol;
}

double PortfolioRisk(){
   double sum=0;

   // No unmodelled pending exposure anywhere on this account.
   if(OrdersTotal()>0) return DBL_MAX;

   for(int i=0;i<PositionsTotal();i++){
      if(PositionGetTicket(i)==0) return DBL_MAX;

      string sym=PositionGetString(POSITION_SYMBOL);
      MqlTick t;
      if(!SymbolInfoTick(sym,t) || t.bid<=0 || t.ask<=0)
         return DBL_MAX;

      int dir=PositionGetInteger(POSITION_TYPE)==
              POSITION_TYPE_BUY?1:-1;

      double vol=PositionGetDouble(POSITION_VOLUME);
      double sl=PositionGetDouble(POSITION_SL);

      double a=RiskCash(sym,dir,vol,
         PositionGetDouble(POSITION_PRICE_OPEN),sl,false);

      double b=RiskCash(sym,dir,vol,
         dir>0?t.bid:t.ask,sl,false);

      if(a==DBL_MAX || b==DBL_MAX) return DBL_MAX;
      sum+=MathMax(a,b);
   }
   return sum;
}

double VolumeFloor(double v){
   double step=SymbolInfoDouble(S,SYMBOL_VOLUME_STEP);
   double mn=SymbolInfoDouble(S,SYMBOL_VOLUME_MIN);
   double mx=MathMin(InpMaxLot,
                    SymbolInfoDouble(S,SYMBOL_VOLUME_MAX));

   if(step<=0 || mx<mn) return 0;

   double x=NormalizeDouble(
      MathFloor((MathMin(v,mx)+1e-10)/step)*step,8);

   return x+1e-9>=mn?x:0;
}

double CostOffset(double entry){
   double probe=SymbolInfoDouble(S,SYMBOL_VOLUME_MIN),p=0;
   if(!OrderCalcProfit(ORDER_TYPE_BUY,S,probe,
                       entry,entry+ts,p) || p<=0)
      return DBL_MAX;

   return InpCostPerLot*probe/p*ts
          +MathMax(InpRiskSlipPoints,InpDeviationPoints)*pt;
}

bool Capacity(int dir,double atr){
   int count=0;

   for(int i=0;i<PositionsTotal();i++){
      ulong ticket=PositionGetTicket(i);
      if(ticket==0) return false;
      if(PositionGetString(POSITION_SYMBOL)!=S) continue;

      // Never aggregate, reverse, or add to netted symbol exposure.
      if(!hedge) return false;
      if(!OwnSelected()) continue;

      count++;

      if(!InpAllowPyramiding ||
         (PositionGetInteger(POSITION_TYPE)==
          POSITION_TYPE_BUY?1:-1)!=dir) return false;

      double e=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double cost=CostOffset(e);
      MqlTick t;

      if(cost==DBL_MAX || !SymbolInfoTick(S,t)) return false;

      if(PositionGetDouble(POSITION_PROFIT)<=
         InpCostPerLot*PositionGetDouble(POSITION_VOLUME) ||
         dir*(sl-e)<cost ||
         dir*((dir>0?t.ask:t.bid)-e)<
         InpScaleSpacingATR*atr) return false;
   }

   return count<InpMaxPositions;
}

double Size(Signal &s,MqlTick &t){
   double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   double factor=s.score>=InpHighScore?InpHighMultiplier:1.0;
   if(s.regime==2) factor*=InpExtremeRiskMultiplier;

   double target=equity*
      MathMin(InpMaxTradeRiskPct,InpBaseRiskPct*factor)/100;

   double available=equity*InpMaxOpenRiskPct/100-PortfolioRisk();
   double budget=MathMin(target,available);
   double probe=SymbolInfoDouble(S,SYMBOL_VOLUME_MIN);

   double unit=RiskCash(S,s.dir,probe,
      s.dir>0?t.ask:t.bid,s.sl,true)/probe;

   if(equity<=0 || budget<=0 ||
      !MathIsValidNumber(unit) ||
      unit<=0 || unit>=DBL_MAX/100) return 0;

   double v=VolumeFloor(budget/unit);
   double step=SymbolInfoDouble(S,SYMBOL_VOLUME_STEP);
   double minimum=MathMax(0.01,MathMax(InpMinLot,probe));

   minimum=NormalizeDouble(
      MathCeil((minimum-1e-10)/step)*step,8);

   if(v<minimum){
      v=minimum;

      // Promotion may exceed target risk, never hard safety ceilings.
      if(v>InpMaxLot ||
         v>SymbolInfoDouble(S,SYMBOL_VOLUME_MAX) ||
         v*unit>equity*InpMaxTradeRiskPct/100 ||
         v*unit>available) return 0;
   }

   if(v*unit>equity*InpMaxTradeRiskPct/100 ||
      v*unit>available) return 0;

   return v;
}

double High(int start,int count){
   double x=-DBL_MAX;
   for(int i=start;i<start+count;i++)
      x=MathMax(x,bars[i].high);
   return x;
}

double Low(int start,int count){
   double x=DBL_MAX;
   for(int i=start;i<start+count;i++)
      x=MathMin(x,bars[i].low);
   return x;
}

// Direction-transformed prices give exact mirrored short logic.
double O(int i,int d){return d*bars[i].open;}
double C(int i,int d){return d*bars[i].close;}
double H(int i,int d){
   return d>0?bars[i].high:-bars[i].low;
}
double L(int i,int d){
   return d>0?bars[i].low:-bars[i].high;
}
double Level(int start,int count,int d){
   return d>0?High(start,count):-Low(start,count);
}

bool Candle(int i,int d){
   double range=H(i,d)-L(i,d);
   return range>0 &&
      C(i,d)>O(i,d) &&
      (C(i,d)-O(i,d))/range>=InpBodyFraction &&
      (C(i,d)-L(i,d))/range>=InpCloseLocation;
}

bool Stops(Signal &s,Features &f,MqlTick &t){
   double entry=s.dir>0?t.ask:t.bid;
   double mult=f.regime==0?InpStopATRNormal:
      (f.regime==1?InpStopATRExpanding:InpStopATRExtreme);

   double swing=s.dir>0 ?
      Low(1,3)-InpStructureBufferATR*f.atr :
      High(1,3)+InpStructureBufferATR*f.atr;

   double dist=MinDistance();

   if(s.dir>0){
      s.sl=Down(MathMin(
         MathMin(entry-mult*f.atr,swing),t.bid-dist));
   }
   else{
      s.sl=Up(MathMax(
         MathMax(entry+mult*f.atr,swing),t.ask+dist));
   }

   s.risk=s.dir*(entry-s.sl);
   if(s.risk<=0 || s.risk>InpMaxStopATR*f.atr) return false;

   double target=entry+s.dir*InpTargetR*s.risk;

   if(InpCapTPAtStructure){
      double nearest=DBL_MAX;
      for(int i=2;i<=InpStructureBars;i++){
         double level=s.dir>0?bars[i].high:bars[i].low;
         double room=s.dir*(level-entry)
                     -InpStructureBufferATR*f.atr;
         if(room>0) nearest=MathMin(nearest,room);
      }
      if(nearest<DBL_MAX)
         target=entry+s.dir*
            MathMin(InpTargetR*s.risk,nearest);
   }

   s.tp=s.dir>0 ?
      Up(MathMax(target,t.bid+dist)) :
      Down(MathMin(target,t.ask-dist));

   s.rr=s.dir*(s.tp-entry)/s.risk;

   return s.sl>0 && s.tp>0 && s.rr>=InpMinTargetR;
}

int Score(Signal &s,Features &f,MqlTick &t){
   int d=s.dir,v=0;

   if(f.bias==d) v+=20;
   if(d*(f.fast-f.slow)>0) v+=10;

   bool mom=d*(bars[1].close-bars[2].close)>=
            InpMomentumATR*f.atr;

   if(mom) v+=10;
   if(f.volRatio>=1.0) v+=5;

   v+=(s.module==1 ?
      (f.regime==0?10:5) :
      (f.regime==1?10:5));

   double range=bars[1].high-bars[1].low;
   if(range>0){
      if((C(1,d)-O(1,d))/range>=0.50) v+=5;
      if((C(1,d)-L(1,d))/range>=0.80) v+=5;
   }

   v+=10; // Completed module-specific setup.

   double sp=t.ask-t.bid;
   if(sp<=0.60*InpMaxSpreadPoints*pt &&
      (InpMaxSpreadATR<=0 ||
       sp/f.atr<=0.60*InpMaxSpreadATR))
      v+=10;
   else
      v+=5;

   if(s.rr>=InpTargetR-0.02) v+=5;
   if(s.rr>=1.40) v+=10;
   else if(s.rr>=InpMinTargetR) v+=5;

   return MathMin(100,v);
}

bool Build(int d,int module,Features &f,
           MqlTick &t,Signal &s){
   if(!Candle(1,d)) return false;

   bool mom=d*(bars[1].close-bars[2].close)>=
            InpMomentumATR*f.atr;

   if(!mom && f.volRatio<1.20) return false;

   double entry=d*(d>0?t.ask:t.bid);

   if(entry-C(1,d)>InpMaxChaseATR*f.atr ||
      MathAbs(entry-C(1,d))>0.75*f.atr) return false;

   if(module==1){
      if(f.regime==2 || f.bias!=d ||
         d*(f.fast-f.slow)<=0) return false;

      bool prior=C(2,d)<O(2,d) ||
         H(2,d)-L(2,d)<=0.65*f.atr;

      if(!prior ||
         L(1,d)>d*f.fast+InpPullbackToleranceATR*f.atr ||
         L(1,d)<d*f.slow-0.40*f.atr ||
         C(1,d)<d*f.fast ||
         C(1,d)<=C(2,d)) return false;
   }
   else{
      if(f.regime==0 || f.bias==-d) return false;

      double lev=Level(2,InpBreakoutBars,d);
      double old=Level(3,InpBreakoutBars,d);

      bool direct=
         f.regime==1 &&
         C(1,d)>lev+InpBreakoutBufferATR*f.atr &&
         C(1,d)-lev<=InpMaxChaseATR*f.atr &&
         f.volRatio>=InpVolumeExpansion &&
         f.rangeRatio>=InpMinBreakoutRangeATR &&
         f.rangeRatio<=InpMaxBreakoutRangeATR;

      bool retest=
         C(2,d)>old+InpBreakoutBufferATR*f.atr &&
         Candle(2,d) &&
         f.vol2>=InpVolumeExpansion &&
         L(1,d)<=old+InpRetestToleranceATR*f.atr &&
         L(1,d)>=old-0.35*f.atr &&
         C(1,d)>=old+InpBreakoutBufferATR*f.atr &&
         C(1,d)-old<=InpMaxChaseATR*f.atr &&
         f.rangeRatio<=InpMaxRetestRangeATR &&
         (H(2,d)-L(2,d))/f.atr<=InpMaxRetestRangeATR;

      if(!direct && !retest) return false;
   }

   s.dir=d;
   s.module=module;
   s.regime=f.regime;

   if(!Stops(s,f,t)) return false;

   s.score=Score(s,f,t);
   return s.score>=InpMinScore;
}

bool KnownNoFill(uint c){
   return
      c==TRADE_RETCODE_REQUOTE ||
      c==TRADE_RETCODE_PRICE_CHANGED ||
      c==TRADE_RETCODE_PRICE_OFF ||
      c==TRADE_RETCODE_REJECT ||
      c==TRADE_RETCODE_CANCEL ||
      c==TRADE_RETCODE_INVALID ||
      c==TRADE_RETCODE_INVALID_VOLUME ||
      c==TRADE_RETCODE_INVALID_PRICE ||
      c==TRADE_RETCODE_INVALID_STOPS ||
      c==TRADE_RETCODE_TRADE_DISABLED ||
      c==TRADE_RETCODE_MARKET_CLOSED ||
      c==TRADE_RETCODE_NO_MONEY ||
      c==TRADE_RETCODE_TOO_MANY_REQUESTS ||
      c==TRADE_RETCODE_FROZEN ||
      c==TRADE_RETCODE_INVALID_FILL ||
      c==TRADE_RETCODE_CLIENT_DISABLES_AT ||
      c==TRADE_RETCODE_SERVER_DISABLES_AT ||
      c==TRADE_RETCODE_LIMIT_VOLUME ||
      c==TRADE_RETCODE_LIMIT_POSITIONS ||
      c==TRADE_RETCODE_LONG_ONLY ||
      c==TRADE_RETCODE_SHORT_ONLY ||
      c==TRADE_RETCODE_CLOSE_ONLY ||
      c==TRADE_RETCODE_HEDGE_PROHIBITED ||
      c==TRADE_RETCODE_FIFO_CLOSE;
}

void CloseOwned(ulong ticket,string why){
   if(!PositionSelectByTicket(ticket) || !OwnSelected())
      return;

   ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   double vol=PositionGetDouble(POSITION_VOLUME);
   string ck=IDKey("c",id);
   double pending=Load(ck,0);

   // Never duplicate an unresolved close.
   if(pending>0 && vol>=pending-1e-9) return;
   if(pending>0) Save(ck,0);

   string throttle=IDKey("z",id);
   if(TimeCurrent()<(datetime)Load(throttle,0)) return;
   Save(throttle,(double)(TimeCurrent()+1));

   MqlTick t;
   if(!SymbolInfoTick(S,t)) return;

   MqlTradeRequest r={};
   MqlTradeResult out={};

   r.action=TRADE_ACTION_DEAL;
   r.symbol=S;
   r.position=ticket;
   r.magic=InpMagic;
   r.volume=vol;

   r.type=PositionGetInteger(POSITION_TYPE)==
      POSITION_TYPE_BUY?ORDER_TYPE_SELL:ORDER_TYPE_BUY;

   r.price=r.type==ORDER_TYPE_SELL?t.bid:t.ask;
   r.deviation=(ulong)InpDeviationPoints;
   r.type_filling=Filling();
   r.comment="AP safety close";

   bool ok=OrderSend(r,out);

   PrintFormat("CLOSE %I64u %s sent=%d ret=%u %s",
      ticket,why,(int)ok,out.retcode,out.comment);

   if(out.retcode==TRADE_RETCODE_DONE ||
      out.retcode==TRADE_RETCODE_DONE_PARTIAL){
      Save(ck,vol);
      return;
   }

   if(!KnownNoFill(out.retcode)){
      Save(ck,vol);
      Ambiguous("Unresolved close");
   }
}

void Modify(ulong ticket,double newSL,MqlTick &t){
   if(!PositionSelectByTicket(ticket) || !OwnSelected())
      return;

   ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
   string mk=IDKey("m",id),bk=IDKey("b",id);

   if(Load(bk,0)>0 ||
      TimeCurrent()<(datetime)Load(mk,0)) return;

   int d=PositionGetInteger(POSITION_TYPE)==
         POSITION_TYPE_BUY?1:-1;

   double old=PositionGetDouble(POSITION_SL);
   double tp=PositionGetDouble(POSITION_TP);
   double dist=MinDistance();
   double close=d>0?t.bid:t.ask;

   if(old<=0 || tp<=0 ||
      d*(newSL-old)<MathMax(ts,InpTrailStepPoints*pt) ||
      d*(close-newSL)<dist ||
      d*(tp-close)<dist) return;

   double freeze=
      SymbolInfoInteger(S,SYMBOL_TRADE_FREEZE_LEVEL)*pt;

   if(d*(close-old)<=freeze ||
      d*(tp-close)<=freeze) return;

   MqlTradeRequest r={};
   MqlTradeResult out={};

   r.action=TRADE_ACTION_SLTP;
   r.position=ticket;
   r.symbol=S;
   r.magic=InpMagic;
   r.sl=newSL;
   r.tp=tp;

   Save(mk,(double)(TimeCurrent()+InpModifyIntervalSeconds));
   bool ok=OrderSend(r,out);

   if(out.retcode==TRADE_RETCODE_DONE ||
      out.retcode==TRADE_RETCODE_NO_CHANGES) return;

   PrintFormat("MODIFY %I64u sent=%d ret=%u %s",
      ticket,(int)ok,out.retcode,out.comment);

   if(!KnownNoFill(out.retcode)){
      Save(bk,1);
      Ambiguous("Unresolved stop modification");
   }

   Cooldown(InpErrorCooldownSeconds);
}

void Manage(MqlTick &t){
   for(int i=PositionsTotal()-1;i>=0;i--){
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !OwnSelected()) continue;

      ulong id=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
      double e=PositionGetDouble(POSITION_PRICE_OPEN);
      double sl=PositionGetDouble(POSITION_SL);
      double tp=PositionGetDouble(POSITION_TP);
      double vol=PositionGetDouble(POSITION_VOLUME);

      int d=PositionGetInteger(POSITION_TYPE)==
            POSITION_TYPE_BUY?1:-1;

      if(sl<=0 || tp<=0){
         CloseOwned(ticket,"missing protective SL/TP");
         continue;
      }

      double cash=RiskCash(S,d,vol,e,sl,false);

      if(cash==DBL_MAX ||
         cash>AccountInfoDouble(ACCOUNT_EQUITY)*
              InpMaxTradeRiskPct/100+0.01){
         CloseOwned(ticket,"post-fill hard-risk breach");
         continue;
      }

      if(eqHalt && InpCloseOnEquityEmergency){
         CloseOwned(ticket,"equity emergency");
         continue;
      }

      if(Load(IDKey("c",id),0)>0){
         CloseOwned(ticket,"pending residual close");
         continue;
      }

      string rk=IDKey("r",id);
      double R=Load(rk,0);

      if(R<=0){
         R=d*(e-sl);
         if(R<=0){
            CloseOwned(ticket,"original R unavailable");
            continue;
         }
         Save(rk,R);
      }

      if(atrCache<=0) continue;

      double close=d>0?t.bid:t.ask;
      double move=d*(close-e);
      double next=sl;
      double cost=CostOffset(e);

      if(cost==DBL_MAX) continue;

      double offset=cost+InpBEOffsetATR*atrCache
                    +(t.ask-t.bid);

      if(move>=InpBETriggerR*R){
         double x=e+d*offset;
         next=d>0?MathMax(next,x):MathMin(next,x);
      }

      if(move>=InpLockTriggerR*R){
         double x=e+d*MathMax(offset,InpLockR*R);
         next=d>0?MathMax(next,x):MathMin(next,x);
      }

      if(move>=InpTrailStartR*R){
         double x=close-d*InpTrailATR*atrCache;

         if(InpSwingTrail){
            MqlRates z[];
            ArraySetAsSeries(z,true);

            if(CopyRates(S,PERIOD_M1,1,
                         InpSwingTrailBars,z)==InpSwingTrailBars){
               double swing=d>0?DBL_MAX:-DBL_MAX;

               for(int j=0;j<InpSwingTrailBars;j++)
                  swing=d>0 ?
                     MathMin(swing,z[j].low) :
                     MathMax(swing,z[j].high);

               double sx=swing
                         -d*InpStructureBufferATR*atrCache;

               x=d>0?MathMax(x,sx):MathMin(x,sx);
            }
         }

         next=d>0?MathMax(next,x):MathMin(next,x);
      }

      // Clamp to legality, then require improvement over the held stop.
      next=d>0 ?
         Down(MathMin(next,t.bid-MinDistance())) :
         Up(MathMax(next,t.ask+MinDistance()));

      if(d*(next-sl)>0) Modify(ticket,next,t);
   }
}

void EquitySafety(){
   double eq=AccountInfoDouble(ACCOUNT_EQUITY);

   if(eq>peak){
      peak=eq;
      Save("peak",peak);
   }

   if(InpEquityEmergency && peak>0 &&
      100*(peak-eq)/peak>=InpEquityDDPct){
      if(!eqHalt)
         Print("EMERGENCY equity drawdown latch; no daily reset.");

      eqHalt=true;
      Save("eqHalt",1);
   }
}

bool MarginOK(MqlTradeRequest &r){
   MqlTradeCheckResult c={};

   if(!OrderCheck(r,c)){
      Log(StringFormat(
         "OrderCheck failed ret=%u %s error=%d",
         c.retcode,c.comment,GetLastError()));
      return false;
   }

   return
      (c.retcode==0 || c.retcode==TRADE_RETCODE_DONE) &&
      c.equity>0 &&
      c.margin_free>0 &&
      100*c.margin/c.equity<=InpMaxMarginUsagePct;
}

void Place(Signal &s,Features &f){
   for(int attempt=0;attempt<2;attempt++){
      if(TimeCurrent()-lastBar>InpMaxSignalAgeSeconds ||
         !UserSession() || uncertain) return;

      MqlTick t;
      if(!SymbolInfoTick(S,t) ||
         !ExecutionOK(t,f,s.dir) ||
         !Capacity(s.dir,f.atr)) return;

      Signal refreshed;
      if(!Build(s.dir,s.module,f,t,refreshed)) return;

      s=refreshed;
      double vol=Size(s,t);
      if(vol<=0) return;

      MqlTradeRequest r={};
      MqlTradeResult out={};

      r.action=TRADE_ACTION_DEAL;
      r.symbol=S;
      r.magic=InpMagic;
      r.volume=vol;
      r.type=s.dir>0?ORDER_TYPE_BUY:ORDER_TYPE_SELL;
      r.price=s.dir>0?t.ask:t.bid;
      r.sl=s.sl;
      r.tp=s.tp;
      r.deviation=(ulong)InpDeviationPoints;
      r.type_filling=Filling();
      r.comment=StringFormat("AP M%d R%d S%d",
                             s.module,s.regime,s.score);

      if(!MarginOK(r)) return;

      bool ok=OrderSend(r,out);

      PrintFormat(
         "ENTRY bar=%s module=%d regime=%d score=%d "
         "vol=%.8f SL=%.*f TP=%.*f sent=%d ret=%u "
         "deal=%I64u order=%I64u %s",
         TimeToString(lastBar),s.module,s.regime,s.score,
         vol,digits,s.sl,digits,s.tp,
         (int)ok,out.retcode,out.deal,out.order,out.comment);

      if(out.retcode==TRADE_RETCODE_DONE ||
         out.retcode==TRADE_RETCODE_DONE_PARTIAL){

         bool reconciled=false;
         ulong newID=0;

         if(out.deal>0 && HistoryDealSelect(out.deal)){
            ulong id=(ulong)HistoryDealGetInteger(
               out.deal,DEAL_POSITION_ID);
            newID=id;

            if(id>0 && PositionAlive(id))
               reconciled=true;
            else if(id>0 && HistorySelectByPosition(id)){
               double balance=0;

               for(int j=0;j<HistoryDealsTotal();j++){
                  ulong dd=HistoryDealGetTicket(j);
                  long en=HistoryDealGetInteger(dd,DEAL_ENTRY);

                  if(en==DEAL_ENTRY_IN)
                     balance+=HistoryDealGetDouble(dd,DEAL_VOLUME);

                  if(en==DEAL_ENTRY_OUT ||
                     en==DEAL_ENTRY_OUT_BY)
                     balance-=HistoryDealGetDouble(dd,DEAL_VOLUME);
               }

               // Already fully closed by SL/TP.
               reconciled=MathAbs(balance)<1e-8;
            }
         }

         if(!reconciled)
            Ambiguous("Successful entry not yet reconciled "
                      "in terminal state");

         MqlTick latest;
         if(SymbolInfoTick(S,latest)) Manage(latest);

         if(newID>0 &&
            PortfolioRisk()>
            AccountInfoDouble(ACCOUNT_EQUITY)*
            InpMaxOpenRiskPct/100+0.01){

            for(int i=PositionsTotal()-1;i>=0;i--){
               ulong ticket=PositionGetTicket(i);

               if(ticket>0 &&
                  (ulong)PositionGetInteger(
                     POSITION_IDENTIFIER)==newID){
                  CloseOwned(ticket,
                     "post-fill portfolio-risk breach");
                  break;
               }
            }
         }
         return;
      }

      bool retry=
         out.retcode==TRADE_RETCODE_REQUOTE ||
         out.retcode==TRADE_RETCODE_PRICE_CHANGED;

      if(retry && attempt==0 && InpSafeRequoteRetry)
         continue;

      if(!KnownNoFill(out.retcode))
         Ambiguous("Unresolved entry; NEVER blindly resend");

      Cooldown(InpErrorCooldownSeconds);
      return;
   }
}

bool ClaimBar(datetime bar){
   if(Tester()) return true;

   string key=Key("bar");

   if(!GlobalVariableCheck(key))
      GlobalVariableSet(key,0);

   double previous=GlobalVariableGet(key);
   if(previous>=(double)bar) return false;

   return GlobalVariableSetOnCondition(
      key,(double)bar,previous);
}

void Evaluate(){
   if(!InpEnableEntries || eqHalt || lossHalt ||
      uncertain || !UserSession() ||
      TimeCurrent()<holdUntil ||
      TimeCurrent()-lastBar>InpMaxSignalAgeSeconds)
      return;

   Features f;
   if(!ReadFeatures(f)){
      Log("Closed-bar data not ready; signal skipped.");
      return;
   }

   MqlTick t;
   if(!SymbolInfoTick(S,t)) return;

   Signal best;
   best.score=-1;

   for(int d=-1;d<=1;d+=2){
      for(int m=1;m<=2;m++){
         if((m==1 && !InpPullback) ||
            (m==2 && !InpBreakout) ||
            !ExecutionOK(t,f,d)) continue;

         Signal x;
         if(Build(d,m,f,t,x) && x.score>best.score)
            best=x;
      }
   }

   if(best.score>=InpMinScore) Place(best,f);
}

bool Validate(){
   if(InpMagic==0 ||
      InpFastM1<2 || InpSlowM1<=InpFastM1 ||
      InpFastM5<2 || InpSlowM5<=InpFastM5 ||
      InpATRPeriod<2 || InpATRBaseline<2 ||
      InpVolumeBars<2 || InpBreakoutBars<2 ||
      InpStructureBars<InpBreakoutBars+2 ||
      InpSlopeBars<1 || InpSwingTrailBars<1)
      return false;

   if(InpMinScore<0 ||
      InpHighScore<InpMinScore || InpHighScore>100 ||
      InpBaseRiskPct<=0 ||
      InpMaxTradeRiskPct<InpBaseRiskPct ||
      InpMaxOpenRiskPct<InpMaxTradeRiskPct ||
      InpHighMultiplier<1 ||
      InpExtremeRiskMultiplier<=0 ||
      InpExtremeRiskMultiplier>1 ||
      InpMinLot<0.01 || InpMaxLot<InpMinLot ||
      InpMaxPositions<1 || InpCostPerLot<0 ||
      InpRiskSlipPoints<0 || InpDeviationPoints<0 ||
      InpMaxMarginUsagePct<=0 ||
      InpMaxMarginUsagePct>100)
      return false;

   if(InpExpandATR<=0 ||
      InpExtremeATR<=InpExpandATR ||
      InpExpandRange<=0 ||
      InpExtremeRange<=InpExpandRange ||
      InpBodyFraction<=0 || InpBodyFraction>1 ||
      InpCloseLocation<0.5 || InpCloseLocation>1 ||
      InpVolumeExpansion<1 ||
      InpStopATRNormal<=0 ||
      InpStopATRExpanding<=0 ||
      InpStopATRExtreme<=0 ||
      InpMaxStopATR<=0 ||
      InpTargetR<InpMinTargetR ||
      InpMinTargetR<=0 ||
      InpMaxBreakoutRangeATR<InpMinBreakoutRangeATR ||
      InpMaxRetestRangeATR<=0)
      return false;

   if(InpMaxSpreadPoints<=0 ||
      InpMaxSpreadATR<0 ||
      InpAbnormalSpreadRatio<=1 ||
      InpSpreadEWMAAlpha<=0 || InpSpreadEWMAAlpha>1 ||
      InpMaxJumpATR<=0 || InpMaxSpeedATRPerSec<=0 ||
      InpMaxTickAgeSeconds<1 ||
      InpMaxSignalAgeSeconds<1 ||
      InpErrorCooldownSeconds<0 ||
      InpShockCooldownSeconds<0 ||
      InpModifyIntervalSeconds<1 ||
      InpTrailStepPoints<0 ||
      InpStopSafetyPoints<0 ||
      InpBETriggerR<=0 ||
      InpBEOffsetATR<0 ||
      InpLockTriggerR<InpBETriggerR ||
      InpLockR<0 ||
      InpTrailStartR<InpBETriggerR ||
      InpTrailATR<=0 ||
      InpEquityDDPct<=0 || InpEquityDDPct>=100 ||
      InpMaxConsecutiveLosses<0 ||
      InpSlopeATR<0 ||
      InpPullbackToleranceATR<0 ||
      InpMomentumATR<0 ||
      InpBreakoutBufferATR<0 ||
      InpRetestToleranceATR<0 ||
      InpMaxChaseATR<=0 ||
      InpMinBreakoutRangeATR<=0 ||
      InpStructureBufferATR<0 ||
      InpScaleSpacingATR<0)
      return false;

   for(int i=0;i<6;i++)
      if(sessions[i]<0) return false;

   return true;
}

int OnInit(){
   S=InpSymbol==""?_Symbol:InpSymbol;

   // OnTick belongs to the chart, not an arbitrary input symbol.
   if(S!=_Symbol || _Period!=PERIOD_M1 ||
      !SymbolSelect(S,true)){
      Print("Attach to the exact configured symbol's M1 chart.");
      return INIT_PARAMETERS_INCORRECT;
   }

   sessions[0]=ParseTime(InpAsiaStart);
   sessions[1]=ParseTime(InpAsiaEnd);
   sessions[2]=ParseTime(InpLondonStart);
   sessions[3]=ParseTime(InpLondonEnd);
   sessions[4]=ParseTime(InpNewYorkStart);
   sessions[5]=ParseTime(InpNewYorkEnd);

   if(!Validate()) return INIT_PARAMETERS_INCORRECT;

   pt=SymbolInfoDouble(S,SYMBOL_POINT);
   ts=SymbolInfoDouble(S,SYMBOL_TRADE_TICK_SIZE);
   digits=(int)SymbolInfoInteger(S,SYMBOL_DIGITS);

   if(pt<=0 || ts<=0 ||
      SymbolInfoDouble(S,SYMBOL_VOLUME_STEP)<=0 ||
      SymbolInfoDouble(S,SYMBOL_VOLUME_MIN)<=0 ||
      SymbolInfoDouble(S,SYMBOL_VOLUME_MAX)<InpMinLot)
      return INIT_FAILED;

   long orderMode=SymbolInfoInteger(S,SYMBOL_ORDER_MODE);
   long fill=SymbolInfoInteger(S,SYMBOL_FILLING_MODE);

   if((orderMode & SYMBOL_ORDER_MARKET)==0 ||
      (orderMode & SYMBOL_ORDER_SL)==0 ||
      (orderMode & SYMBOL_ORDER_TP)==0)
      return INIT_FAILED;

   if(SymbolInfoInteger(S,SYMBOL_TRADE_EXEMODE)==
      SYMBOL_TRADE_EXECUTION_MARKET &&
      (fill & (SYMBOL_FILLING_FOK|SYMBOL_FILLING_IOC))==0)
      return INIT_FAILED;

   hedge=AccountInfoInteger(ACCOUNT_MARGIN_MODE)==
         ACCOUNT_MARGIN_MODE_RETAIL_HEDGING;

   K=StringFormat("AP.%I64d.%I64u.%s",
      AccountInfoInteger(ACCOUNT_LOGIN),InpMagic,S);

   if(StringLen(K)>36){
      Print("State key too long: use shorter symbol/magic combination.");
      return INIT_FAILED;
   }

   hFast=iMA(S,PERIOD_M1,InpFastM1,0,MODE_EMA,PRICE_CLOSE);
   hSlow=iMA(S,PERIOD_M1,InpSlowM1,0,MODE_EMA,PRICE_CLOSE);
   hATR=iATR(S,PERIOD_M1,InpATRPeriod);
   hHFast=iMA(S,PERIOD_M5,InpFastM5,0,MODE_EMA,PRICE_CLOSE);
   hHSlow=iMA(S,PERIOD_M5,InpSlowM5,0,MODE_EMA,PRICE_CLOSE);
   hHATR=iATR(S,PERIOD_M5,InpATRPeriod);

   if(hFast==INVALID_HANDLE ||
      hSlow==INVALID_HANDLE ||
      hATR==INVALID_HANDLE ||
      hHFast==INVALID_HANDLE ||
      hHSlow==INVALID_HANDLE ||
      hHATR==INVALID_HANDLE)
      return INIT_FAILED;

   double eq=AccountInfoDouble(ACCOUNT_EQUITY);

   if(InpResetSafetyState){
      Save("peak",eq);
      Save("eqHalt",0);
      Save("lossHalt",0);
      Save("uncertain",0);
      Save("epoch",(double)TimeCurrent());

      for(int i=0;i<PositionsTotal();i++){
         if(PositionGetTicket(i)>0 && OwnSelected()){
            ulong id=(ulong)PositionGetInteger(
               POSITION_IDENTIFIER);
            Save(IDKey("c",id),0);
            Save(IDKey("b",id),0);
         }
      }
   }

   peak=Load("peak",eq);
   eqHalt=Load("eqHalt",0)>0;
   lossHalt=Load("lossHalt",0)>0;
   uncertain=Load("uncertain",0)>0;
   epoch=(datetime)Load("epoch",(double)TimeCurrent());

   Save("epoch",(double)epoch);
   Save("peak",peak);

   // Do not retrospectively enter at attachment/restart.
   lastBar=iTime(S,PERIOD_M1,0);
   Buf(hATR,1,atrCache);

   Log(StringFormat(
      "Initialized %s %s; equity=%.2f contract=%.2f "
      "point=%g tick=%g lossTickValue=%g",
      S,hedge?"hedging":"netting",eq,
      SymbolInfoDouble(S,SYMBOL_TRADE_CONTRACT_SIZE),
      pt,ts,
      SymbolInfoDouble(S,SYMBOL_TRADE_TICK_VALUE_LOSS)));

   return INIT_SUCCEEDED;
}

void OnTick(){
   MqlTick t;
   if(!SymbolInfoTick(S,t) || t.bid<=0 || t.ask<=0) return;

   double a;
   if(Buf(hATR,1,a) && a>0) atrCache=a;

   Observe(t);
   EquitySafety();
   Manage(t);

   if(dirty) RefreshLosses();

   datetime bar=iTime(S,PERIOD_M1,0);
   if(bar<=0 || bar==lastBar) return;

   lastBar=bar;
   if(ClaimBar(bar)) Evaluate();
}

void OnTradeTransaction(
   const MqlTradeTransaction &trans,
   const MqlTradeRequest &request,
   const MqlTradeResult &result){

   if(trans.type==TRADE_TRANSACTION_DEAL_ADD ||
      trans.type==TRADE_TRANSACTION_POSITION){
      dirty=true;

      MqlTick t;
      if(SymbolInfoTick(S,t) && t.bid>0 && t.ask>0){
         EquitySafety();
         Manage(t);
      }
   }
}

void OnDeinit(const int reason){
   if(hFast!=INVALID_HANDLE) IndicatorRelease(hFast);
   if(hSlow!=INVALID_HANDLE) IndicatorRelease(hSlow);
   if(hATR!=INVALID_HANDLE) IndicatorRelease(hATR);
   if(hHFast!=INVALID_HANDLE) IndicatorRelease(hHFast);
   if(hHSlow!=INVALID_HANDLE) IndicatorRelease(hHSlow);
   if(hHATR!=INVALID_HANDLE) IndicatorRelease(hHATR);

   if(!Tester()) GlobalVariablesFlush();
}


