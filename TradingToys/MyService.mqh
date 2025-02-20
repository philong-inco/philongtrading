#ifndef __MY_SERVICE__  // Bắt đầu include guard với tên của dự án  
#define __MY_SERVICE__  // Định nghĩa tên include guard 

#property copyright "PhiLongTrading"
#property link      "philong.com"

#include <TradingToys/MyStruct.mqh>

namespace MyService {
   
   // Update giá mới vào mảng theo TIMEFRAME
   bool UpdateDataCandle(string symbol, ENUM_TIMEFRAMES timeFrame, int pos, int count, MqlRates &arrResult[])
   {
      int check = -1;
      switch(timeFrame)
      {
         case PERIOD_M1:
            check = CopyRates(symbol, timeFrame, pos, count, arrCandle_M1);
            break;
         case PERIOD_M3:
            check = CopyRates(symbol, timeFrame, pos, count, arrCandle_M3);
            break;
         case PERIOD_M5:
            check = CopyRates(symbol, timeFrame, pos, count, arrCandle_M5);
            break;
         case PERIOD_M15:
            check = CopyRates(symbol, timeFrame, pos, count, arrCandle_M15);
            break;  
         case PERIOD_M30:
            check = CopyRates(symbol, timeFrame, pos, count, arrCandle_M30);
            break;    
         case PERIOD_H1:
            check = CopyRates(symbol, timeFrame, pos, count, arrCandle_H1);
            break;
         case PERIOD_H4:
            check = CopyRates(symbol, timeFrame, pos, count, arrCandle_H4);
            break;
         case PERIOD_D1:
            check = CopyRates(symbol, timeFrame, pos, count, arrCandle_D1);
            break;
         case PERIOD_W1:
            check = CopyRates(symbol, timeFrame, pos, count, arrCandle_W1);
            break; 
         default:
            Print("Update price failed");
            break;      
      }
   
      return check >= 0;
   }

   // Chờ đợi cho tới giây đầu tiên của phút mới
   void PrepareTime(CloseCandleInfo &tfClose)
   {
      MqlDateTime result;
      // Lặp liên tục cho tới khi chuyển sang phút mới
      while(!IsNewMinute(1, result)){ }
      
      // Thiết lập chu kỳ gọi hàm OnTimer() --60 giây
      EventSetTimer(60);
      SetCloseTimeFrame(tfClose);
      OnTimer();
      
   }

   // Trả về true nếu giây là 1
   bool IsNewMinute(int sec, MqlDateTime &result)
   {
      // Lấy time hiện tại
      TimeToStruct(TimeCurrent(), result);
      // Check nếu giây = 1 có nghĩa là phút mới (1 là để cho chắc chắn)
      if(result.sec == sec) 
         return true;
      return false;
   }
   
   // Đếm số phút/giờ còn lại để đóng nến các TIMEFRAME
   void SetCloseTimeFrame(CloseCandleInfo &tfClose)
   {
      MqlDateTime m3;
      MqlDateTime m5;
      MqlDateTime m15;
      MqlDateTime m30;
      MqlDateTime h1;
      MqlDateTime h4;
      MqlDateTime d1;
      MqlDateTime w1;
      MqlDateTime now;
      TimeToStruct(iTime(_Symbol, PERIOD_M3, 0) , m3);   // Thời gian mở cửa của nến M3 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_M5, 0) , m5);   // Thời gian mở cửa của nến M5 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_M15, 0), m15);  // Thời gian mở cửa của nến M15 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_M30, 0), m30);  // Thời gian mở cửa của nến M30 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_H1, 0) , h1);   // Thời gian mở cửa của nến H1 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_H4, 0) , h4);   // Thời gian mở cửa của nến H4 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_D1, 0) , d1);   // Thời gian mở cửa của nến D1 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_W1, 0) , w1);   // Thời gian mở cửa của nến W1 hiện tại
      TimeToStruct(TimeCurrent(), now);                  // Thời gian hiện tại
      
      // Thời gian đóng nến = Thời gian mặc định nến - (thời gian đã chạy được trên nến hiện tại)
      tfClose.M3  = 3   - (now.min  - m3.min);
      tfClose.M5  = 5   - (now.min  - m5.min);
      tfClose.M15 = 15  - (now.min  - m15.min);
      tfClose.M30 = 30  - (now.min  - m30.min);
      tfClose.H1  = 60  - (now.min  - h1.min);
      tfClose.H4  = 4   - (now.hour - h4.hour);
      tfClose.D1  = 24  - (now.hour - d1.hour);
      tfClose.W1  = 7   - (now.day  - w1.day);
      Print("Thời gian để đóng nến hiện tại:");
      Print("M3: ", tfClose.M3, "|", now.min, "-", m3.min);
      Print("M5: ", tfClose.M5, "|", now.min, "-", m5.min);
      Print("M15: ", tfClose.M15, "|", now.min, "-", m15.min);
      Print("M30: ", tfClose.M30, "|", now.min, "-", m30.min);
      Print("H1: ", tfClose.H1, "|", now.min, "-", h1.min);
      Print("H4: ", tfClose.H4, "|", now.hour, "-", h4.hour);
      Print("D1: ", tfClose.D1, "|", now.hour, "-", d1.hour);
      Print("W1: ", tfClose.W1, "|", now.day, "-", w1.day);
      Print("-----------------------------------------");
   }
   
   // Kiểm tra thị trường có đang đóng cửa không
   bool IsCloseMarket()
   {
      MqlDateTime isClose;
      TimeToStruct(TimeCurrent(), isClose);
      return (isClose.day_of_week == 5 && isClose.hour == 23 && isClose.min == 59);
   }
   
   // Chuyển mảng nến sang mảng High/Low
   SwingInfo[] ConvertToHighLowArr(MqlRates &arr[])
   {
      SwingInfo arrHighLow[];
      int count = ArraySize(arr);
      for(int i=0;i<count - 1;i++) // lặp từ phần tử đầu tới phần tử "sát cuối" (n-1)
      {
         MqlRates rateCurrent = arr[i];
         MqlRates rateNext = arr[i+1];
         if(IsBullishCandle(rateCurrent) != IsBullishCandle(rateNext)) // check 2 nến khác nhau
         {
            if(IsBullishCandle(rateCurrent)) // nến tăng => đỉnh
            {
               SwingInfo high;
               high.IsHigh = true;
               high.Price = MathMax(rateCurrent.high, rateNext.high);
               high.Time = rateCurrent.high > rateNext.high ? rateCurrent.time : rateNext.time;
               int newLength = ArraySize(arrHighLow) + 1;
               ArrayResize(arrHighLow, newLength);
               arrHighLow[newLength-1] = high;
            } else { // nến giảm => đáy
               SwingInfo low;
               low.IsHigh = false;
               low.Price = MathMin(rateCurrent.low, rateNext.low);
               low.Time = rateCurrent.low < rateNext.low ? rateCurrent.time : rateNext.time;
               int newLength = ArraySize(arrHighLow) + 1;
               ArrayResize(arrHighLow, newLength);
               arrHighLow[newLength-1] = low;
            }
         }
      }
      
      return arrHighLow;
   }
   
   bool IsBullishCandle(MqlRates &rate)
   {
      return rate.open > rate.close;
   }
   
}

#endif