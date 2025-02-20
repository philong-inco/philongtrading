//+------------------------------------------------------------------+
//|                                                       LongEA.mq5 |
//|                                                   PhiLongTrading |
//|                                                      philong.com |
//+------------------------------------------------------------------+
#property copyright "PhiLongTrading"
#property link      "philong.com"
#property version   "1.00"

#include <TradingToys/MyService.mqh>
#include <TradingToys/MyStruct.mqh>

// Thanh khoản input
input double KILL_PLAN_HIGH = -1;
input double KILL_PLAN_LOW = -1;          // Điểm hủy bỏ plan
input double LIQUIDITY_BEFORE = -1;       // Thanh khoản breakout
input double LIQUIDITY_CURRENT = -1;      // Thanh khoản hiện tại
input string Action = ""; // B: buy  S: sell

// Biến lưu điều kiện giao dịch
input bool LiquidityBeforeIsDone = false;
input bool LiquidityCurrentIsDone = false;
input bool HasLiquidityCurrent = false;
input bool HasSignal = false;
input double TPDefault = -1;
input double SLDefault = -1;
// Biến lưu thông số

// Số lượng phần tử trong mảng nến
input int M1_Data_Candles  = 20;
input int M3_Data_Candles  = 20;
input int M5_Data_Candles  = 20;
input int M15_Data_Candles = 20;
input int M30_Data_Candles = 20;
input int H1_Data_Candles  = 20;
input int H4_Data_Candles  = 20;
input int D1_Data_Candles  = 20;
input int W1_Data_Candles  = 20;
input double RISK_PERCENT  = 0; // Phần trăm vốn (%)
input double RISK_FOREVER  = 0; // USD($)
input double RewardRate    = 1.2; // Tỷ lệ lợi nhuận

// Thông tin cơ bản
double Balance = 0;     // Số dư ($)
double Undefine = -1;

// Mảng dữ liệu các TF
MqlDateTime mqlDateTime;
MqlRates arrCandle_M1[];
MqlRates arrCandle_M3[];
MqlRates arrCandle_M5[];
MqlRates arrCandle_M15[];
MqlRates arrCandle_M30[];
MqlRates arrCandle_H1[];
MqlRates arrCandle_H4[];
MqlRates arrCandle_D1[];
MqlRates arrCandle_W1[];

MqlRates candleM1Last[];

CloseCandleInfo tfCloseInfo;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
// Lấy số dư tài khoản
   Balance = AccountInfoDouble(ACCOUNT_BALANCE);
// Quét + bật sự kiện 1 phút
   MyService::PrepareTime(tfCloseInfo);
// Chuẩn bị dữ liệu vào các mảng nến
   PrepareDataCandles();

   return(INIT_SUCCEEDED);
  }

// chạy 1 phút 1 lần
void OnTimer()
  {

   try
     {
      // Check nếu market đóng cửa thì KILL EA
      //if(MyService::IsCloseMarket())
      //OnDeinit(INIT_FAILED);

      // Cập nhật thời gian đóng nến các TF và update dữ liệu các mảng nến
      CaclTimeAndUpdateData();

      // Check các điều kiện đã đạt chưa
      if(LiquidityBeforeIsDone && LiquidityCurrentIsDone)
        {
         SignalFinding(); // Đủ điều kiện => Chạy tìm kiếm signal ở đây
        }
      else
        {
         // Kiểm tra xem nến vừa xong đã quét 2 LQ chưa
         CopyRates(_Symbol, PERIOD_M1, 1, 1, candleM1Last); // lưu nến M1 cuối cùng vào biến toàn cục
         if(!LiquidityBeforeIsDone)
            SweetLiquidityBeforeCheck();
         if(!LiquidityCurrentIsDone)
            SweetLiquidityCurrentCheck();
         // Nếu nến vừa xong thỏa mãn quét 2 LQ thì chạy tìm signal luôn
         if(LiquidityBeforeIsDone && LiquidityCurrentIsDone)
            SignalFinding();
        }
     }
   catch(int error_code)
     {
      Alert("ErrorCode: ", error_code);
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CaclTimeAndUpdateData()
  {
// Mỗi khi có nến M1 mới
   tfCloseInfo.M3 -= 1;
   tfCloseInfo.M5 -= 1;
   tfCloseInfo.M15 -= 1;
   tfCloseInfo.M30 -= 1;
   tfCloseInfo.H1 -= 1;
   MyService::UpdateDataCandle(_Symbol, PERIOD_M1, 1, M1_Data_Candles, arrCandle_M1);

   if(tfCloseInfo.M3 <= 0) // Nếu đóng nến M3 => cập nhật bộ đếm và data
     {
      tfCloseInfo.M3 = 3;
      MyService::UpdateDataCandle(_Symbol, PERIOD_M3, 1, M3_Data_Candles, arrCandle_M3);
     }

   if(tfCloseInfo.M5 <= 0) // Nếu đóng nến M5 => cập nhật bộ đếm và data
     {
      tfCloseInfo.M5 = 5;
      MyService::UpdateDataCandle(_Symbol, PERIOD_M5, 1, M5_Data_Candles, arrCandle_M5);
     }

   if(tfCloseInfo.M15 <= 0) // Nếu đóng nến M15 => cập nhật bộ đếm và data
     {
      tfCloseInfo.M15 = 15;
      MyService::UpdateDataCandle(_Symbol, PERIOD_M15, 1, M15_Data_Candles, arrCandle_M15);
     }

   if(tfCloseInfo.M30 <= 0) // Nếu đóng nến M30 => cập nhật bộ đếm và data
     {
      tfCloseInfo.M30 = 30;
      MyService::UpdateDataCandle(_Symbol, PERIOD_M30, 1, M30_Data_Candles, arrCandle_M30);
     }

   if(tfCloseInfo.H1 <= 0) // Khi đóng nến H1 => cập nhật bộ đếm và data
     {
      tfCloseInfo.H1 = 60;
      MyService::UpdateDataCandle(_Symbol, PERIOD_H1, 1, H1_Data_Candles, arrCandle_H1);
      tfCloseInfo.H4 -= 1;
      tfCloseInfo.D1 -= 1;

      if(tfCloseInfo.H4 <= 0) // Nếu đóng nến H4 => cập nhật bộ đếm và data
        {
         tfCloseInfo.H4 = 4;
         MyService::UpdateDataCandle(_Symbol, PERIOD_H4, 1, H4_Data_Candles, arrCandle_H4);
        }

      if(tfCloseInfo.D1 <= 0) // Nếu đóng nến D1 => cập nhật bộ đếm và data
        {
         tfCloseInfo.D1 = 24;
         MyService::UpdateDataCandle(_Symbol, PERIOD_D1, 1, D1_Data_Candles, arrCandle_D1);
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
// Kill chu kỳ gọi OnTimer() và flush dữ liệu mảng
   EventKillTimer();
   ArrayFree(arrCandle_M1);
   ArrayFree(arrCandle_M3);
   ArrayFree(arrCandle_M5);
   ArrayFree(arrCandle_M15);
   ArrayFree(arrCandle_M30);
   ArrayFree(arrCandle_H1);
   ArrayFree(arrCandle_H4);
   ArrayFree(arrCandle_D1);
   ArrayFree(arrCandle_W1);
   Print("End EA.");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

  }

// Check xem nến vừa đóng có quét thanh khoản breakout không
void SweetLiquidityBeforeCheck()
  {
   if(LIQUIDITY_BEFORE == Undefined)
      return;
   if(LIQUIDITY_BEFORE > candles[0].low && LIQUIDITY_BEFORE < candles[0].high)
     {
      LiquidityBeforeIsDone = true;
     }
  }

// Check xem nến vừa đóng có quét thanh khoản hiện tại không
void SweetLiquidityCurrentCheck()
  {
   if(!HasLiquidityCurrent)
     {
      LiquidityCurrentFinding();
     }
   else
      if(LIQUIDITY_CURRENT LIQUIDITY_CURRENT > candles[0].low && LIQUIDITY_CURRENT < candles[0].high)
        {
         LiquidityCurrentIsDone = true;
        }
  }

// Chạy tìm signal theo Action
void SignalFinding()
  {
   if(LIQUIDITY_CURRENT == Undefine)
      return;
   HasSignal = SignalCheck();
   if(HasSignal)
      CreateOrder();
  }

// Kiểm tra tín hiệu vào lệnh có chưa
bool SignalCheck()
  {

  }

// Tạo lệnh
bool CreateOrder()
  {

  }

// Chạy tìm thanh khoản hiện tại
void LiquidityCurrentFinding()
  {
// tìm được thì gán giá trị cho LIQUIDITY_CURRENT
   LIQUIDITY_CURRENT = 0;
  }

// Khởi tạo mảng và chuẩn bị dữ liệu
void PrepareDataCandles()
  {
   ArrayResize(arrCandle_M1,  M1_Data_Candles);
   ArrayResize(arrCandle_M3,  M3_Data_Candles);
   ArrayResize(arrCandle_M5,  M5_Data_Candles);
   ArrayResize(arrCandle_M30, M30_Data_Candles);
   ArrayResize(arrCandle_H1,  H1_Data_Candles);
   ArrayResize(arrCandle_H4,  H4_Data_Candles);
   ArrayResize(arrCandle_D1,  D1_Data_Candles);
   ArrayResize(arrCandle_W1,  W1_Data_Candles);
   ArrayResize(candleM1Last, 1);
   MyService::UpdateDataCandle(_Symbol, PERIOD_M1, 1, M1_Data_Candles, arrCandle_M1);
   MyService::UpdateDataCandle(_Symbol, PERIOD_M3, 1, M3_Data_Candles, arrCandle_M3);
   MyService::UpdateDataCandle(_Symbol, PERIOD_M5, 1, M5_Data_Candles, arrCandle_M5);
   MyService::UpdateDataCandle(_Symbol, PERIOD_M15, 1, M15_Data_Candles, arrCandle_M15);
   MyService::UpdateDataCandle(_Symbol, PERIOD_M30, 1, M30_Data_Candles, arrCandle_M30);
   MyService::UpdateDataCandle(_Symbol, PERIOD_H1, 1, H1_Data_Candles, arrCandle_H1);
   MyService::UpdateDataCandle(_Symbol, PERIOD_H4, 1, H4_Data_Candles, arrCandle_H4);
   MyService::UpdateDataCandle(_Symbol, PERIOD_D1, 1, D1_Data_Candles, arrCandle_D1);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CancelAllPlan()
  {
   KILL_PLAN_HIGH = -1;
   KILL_PLAN_LOW = -1;
   LIQUIDITY_BEFORE = -1;
   LIQUIDITY_CURRENT = -1;
   LiquidityBeforeIsDone = false;
   LiquidityCurrentIsDone = false;
   HasLiquidityCurrent = false;
   HasSignal = false;
   OnDeinit();
  }



//+------------------------------------------------------------------+
