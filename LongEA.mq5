//+------------------------------------------------------------------+
//|                                                       LongEA.mq5 |
//|                                                   PhiLongTrading |
//|                                                      philong.com |
//+------------------------------------------------------------------+
#property copyright "PhiLongTrading"
#property link "philong.com"
#property version "1.00"

#include <TradingToys/MyService.mqh>
#include <TradingToys/MyStruct.mqh>




// Biến lưu thông số
input double KillPlanHigh = -1;     // Hủy bỏ plan (giá trên)
input double KillPlanLow = -1;      // Hủy bỏ plan (giá dưới)
input double LiquidityBefore = -1;  // Thanh khoản breakout
input double LiquidityCurrent = -1; // Thanh khoản hiện tại
input string Action;                // PlanBuy(B) | PlanSell(S)
// Số lượng phần tử trong mảng nến
input int M1_Data_Candles = 1;  // Số nến M1 trong mảng
input int M3_Data_Candles = 30;  // Số nến M3 trong mảng
input int M5_Data_Candles = 30;  // Số nến M5 trong mảng
input int M15_Data_Candles = 100; // Số nến M15 trong mảng
input int M30_Data_Candles = 1; // Số nến M30 trong mảng
input int H1_Data_Candles = 1;  // Số nến H1 trong mảng
input int H4_Data_Candles = 1;  // Số nến H4 trong mảng
input int D1_Data_Candles = 1;  // Số nến D1 trong mảng
input int W1_Data_Candles = 1;  // Số nến W1 trong mảng
input double RISK_PERCENT = 0;   // Phần trăm vốn (%)
input double RISK_FOREVER = 0;   // USD($)
input double RewardRate = 1.2;   // Tỷ lệ lợi nhuận

const double Undefined = -1;
// Thanh khoản input
double KILL_PLAN_HIGH = Undefined;    // Điểm hủy bỏ plan
double KILL_PLAN_LOW = Undefined;     // Điểm hủy bỏ plan
double LIQUIDITY_BEFORE = Undefined;  // Thanh khoản breakout
double LIQUIDITY_CURRENT = Undefined; // Thanh khoản hiện tại
string ACTION;                        // B: buy  S: sell

// Biến lưu điều kiện giao dịch
bool LIQUIDITY_BEFORE_IS_DONE = false;  // Thanh khoản breakout
bool LIQUIDITY_CURRENT_IS_DONE = false; // Thanh khoản hiện tại
bool HAS_LIQUIDITY_CURRENT = false;     // Trạng thái đã có thanh khoản hiện tại chưa
bool HAS_SIGNAL = false;                // Trạng thái có tín hiệu chưa
double TP_DEFAULT = Undefined;          // Mức giá Takeprofit mặc định
double SL_DEFAULT = Undefined;          // Mức giá Stoploss mặc định

// Thông tin cơ bản
double Balance = 0; // Số dư ($)

// Mảng dữ liệu các TF
MqlRates arrCandle_M1[];  // Mảng nến M1
MqlRates arrCandle_M3[];  // Mảng nến M3
MqlRates arrCandle_M5[];  // Mảng nến M5
MqlRates arrCandle_M15[]; // Mảng nến M15
MqlRates arrCandle_M30[]; // Mảng nến M30
MqlRates arrCandle_H1[];  // Mảng nến H1
MqlRates arrCandle_H4[];  // Mảng nến H4
MqlRates arrCandle_D1[];  // Mảng nến D1
MqlRates arrCandle_W1[];  // Mảng nến W1

MqlRates candleM1Last[]; // Thông tin nến M1 cuối cùng (đã đóng)

CloseCandleInfo tfCloseInfo; // Thời gian đóng nến còn lại

int OnInit()
{
  Balance = AccountInfoDouble(ACCOUNT_BALANCE);
  Print("Số dư: ", Balance);
  MyService::PrepareTime(tfCloseInfo);
  PrepareDataCandles();
  MappingDataInput();
  return (INIT_SUCCEEDED);
}

// Chạy 1 phút 1 lần
void OnTimer()
{
  CaclTimeAndUpdateData();
  // lưu nến M1 cuối cùng vào biến toàn cục
  CopyRates(_Symbol, PERIOD_M1, 1, 1, candleM1Last);
  // Check các điều kiện đã đạt chưa
  if (LIQUIDITY_BEFORE_IS_DONE && LIQUIDITY_CURRENT_IS_DONE)
  {
    // Đủ điều kiện => Chạy tìm kiếm signal ở đây
    SignalFinding();
  }
  else
  {
    // Kiểm tra xem nến vừa xong đã quét 2 LQ chưa
    if (!LIQUIDITY_BEFORE_IS_DONE)
      SweetLiquidityBeforeCheck();
    if (!LIQUIDITY_CURRENT_IS_DONE)
      SweetLiquidityCurrentCheck();

    // Nếu nến vừa xong thỏa mãn quét 2 LQ thì chạy tìm signal luôn
    if (LIQUIDITY_BEFORE_IS_DONE && LIQUIDITY_CURRENT_IS_DONE)
      SignalFinding();
  }
}

/// @brief Mappdata input vào biến toàn cục
void MappingDataInput()
{
  KILL_PLAN_HIGH = KillPlanHigh;
  KILL_PLAN_LOW = KillPlanLow;
  LIQUIDITY_BEFORE = LiquidityBefore;
  LIQUIDITY_CURRENT = LiquidityCurrent;
  ACTION = Action;
}

/// @brief Tính toán lại thời gian đóng nến & update lại mảng nến
void CaclTimeAndUpdateData()
{
  // Mỗi khi có nến M1 mới
  tfCloseInfo.M3 -= 1;
  tfCloseInfo.M5 -= 1;
  tfCloseInfo.M15 -= 1;
  tfCloseInfo.M30 -= 1;
  tfCloseInfo.H1 -= 1;
  MyService::UpdateDataCandle(_Symbol, PERIOD_M1, 1, M1_Data_Candles, arrCandle_M1);

  // Nếu đóng nến M3 => cập nhật bộ đếm và data
  if (tfCloseInfo.M3 <= 0)
  {
    tfCloseInfo.M3 = 3;
    MyService::UpdateDataCandle(_Symbol, PERIOD_M3, 1, M3_Data_Candles, arrCandle_M3);
  }
  // Nếu đóng nến M5 => cập nhật bộ đếm và data
  if (tfCloseInfo.M5 <= 0)
  {
    tfCloseInfo.M5 = 5;
    MyService::UpdateDataCandle(_Symbol, PERIOD_M5, 1, M5_Data_Candles, arrCandle_M5);
  }
  // Nếu đóng nến M15 => cập nhật bộ đếm và data
  if (tfCloseInfo.M15 <= 0)
  {
    tfCloseInfo.M15 = 15;
    MyService::UpdateDataCandle(_Symbol, PERIOD_M15, 1, M15_Data_Candles, arrCandle_M15);
  }
  // Nếu đóng nến M30 => cập nhật bộ đếm và data
  if (tfCloseInfo.M30 <= 0)
  {
    tfCloseInfo.M30 = 30;
    MyService::UpdateDataCandle(_Symbol, PERIOD_M30, 1, M30_Data_Candles, arrCandle_M30);
  }
  // Khi đóng nến H1 => cập nhật bộ đếm và data
  if (tfCloseInfo.H1 <= 0)
  {
    tfCloseInfo.H1 = 60;
    MyService::UpdateDataCandle(_Symbol, PERIOD_H1, 1, H1_Data_Candles, arrCandle_H1);
    tfCloseInfo.H4 -= 1;
    tfCloseInfo.D1 -= 1;

    // Nếu đóng nến H4 => cập nhật bộ đếm và data
    if (tfCloseInfo.H4 <= 0)
    {
      tfCloseInfo.H4 = 4;
      MyService::UpdateDataCandle(_Symbol, PERIOD_H4, 1, H4_Data_Candles, arrCandle_H4);
    }
    // Nếu đóng nến D1 => cập nhật bộ đếm và data
    if (tfCloseInfo.D1 <= 0)
    {
      tfCloseInfo.D1 = 24;
      MyService::UpdateDataCandle(_Symbol, PERIOD_D1, 1, D1_Data_Candles, arrCandle_D1);
    }

    // Check nếu market đóng cửa thì KILL EA
    if (MyService::IsCloseMarket())
      OnDeinit(REASON_REMOVE);
  }
}

// Check xem nến vừa đóng có quét thanh khoản breakout không
void SweetLiquidityBeforeCheck()
{
  if (LIQUIDITY_BEFORE == Undefined)
  {
    LIQUIDITY_BEFORE_IS_DONE = false;
    return;
  }

  if (LIQUIDITY_BEFORE > candleM1Last[0].low && LIQUIDITY_BEFORE < candleM1Last[0].high)
  {
    LIQUIDITY_BEFORE_IS_DONE = true;
  }
}

// Check xem nến vừa đóng có quét thanh khoản hiện tại không
void SweetLiquidityCurrentCheck()
{
  if (!HAS_LIQUIDITY_CURRENT)
  {
    LiquidityCurrentFinding();
  }
  else if (LIQUIDITY_CURRENT > candleM1Last[0].low && LIQUIDITY_CURRENT < candleM1Last[0].high)
  {
    LIQUIDITY_CURRENT_IS_DONE = true;
  }
}

// Chạy tìm signal theo Action
void SignalFinding()
{
  if (LIQUIDITY_CURRENT == Undefined)
    return;
  HAS_SIGNAL = SignalCheck();
  if (HAS_SIGNAL)
  {
    // Tạo lệnh xong là plan hết nhiệm vụ (clear để tránh phút sau tạo lệnh trùng ở 1 setup)
    if (CreateOrder())
      PlanClear();
  }
}

// Kiểm tra tín hiệu vào lệnh có chưa
bool SignalCheck()
{
  return false;
}

/// @brief Tạo lệnh
/// @return true nếu tạo thành công
bool CreateOrder()
{
  return false;
}

// Chạy tìm thanh khoản hiện tại
void LiquidityCurrentFinding()
{
  // tìm được thì gán giá trị cho LIQUIDITY_CURRENT
  LIQUIDITY_CURRENT = 0;
}

// Chuẩn bị dữ liệu vào các mảng nến
void PrepareDataCandles()
{
  ArrayResize(arrCandle_M1, M1_Data_Candles);
  ArrayResize(arrCandle_M3, M3_Data_Candles);
  ArrayResize(arrCandle_M5, M5_Data_Candles);
  ArrayResize(arrCandle_M30, M30_Data_Candles);
  ArrayResize(arrCandle_H1, H1_Data_Candles);
  ArrayResize(arrCandle_H4, H4_Data_Candles);
  ArrayResize(arrCandle_D1, D1_Data_Candles);
  ArrayResize(arrCandle_W1, W1_Data_Candles);
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

/// @brief Xóa bỏ plan, đặt các biến thành mặc định
void PlanClear()
{
  KILL_PLAN_HIGH = Undefined;
  KILL_PLAN_LOW = Undefined;
  LIQUIDITY_BEFORE = Undefined;
  LIQUIDITY_CURRENT = Undefined;
  LIQUIDITY_BEFORE_IS_DONE = false;
  LIQUIDITY_CURRENT_IS_DONE = false;
  HAS_LIQUIDITY_CURRENT = false;
  HAS_SIGNAL = false;
  OnDeinit(REASON_REMOVE); // là tham số báo EA bị tắt khỏi biểu đồ
}

void FlushDatas()
{
  ArrayFree(arrCandle_M1);
  ArrayFree(arrCandle_M3);
  ArrayFree(arrCandle_M5);
  ArrayFree(arrCandle_M15);
  ArrayFree(arrCandle_M30);
  ArrayFree(arrCandle_H1);
  ArrayFree(arrCandle_H4);
  ArrayFree(arrCandle_D1);
  ArrayFree(arrCandle_W1);
}

void OnTick() {}
void OnDeinit(const int reason)
{
  // Kill chu kỳ gọi OnTimer() và flush dữ liệu mảng
  EventKillTimer();
  FlushDatas();
  Print("EA đã kết thúc vào: ", TimeCurrent());
}

//+------------------------------------------------------------------+
