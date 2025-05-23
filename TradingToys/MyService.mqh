#ifndef __MY_SERVICE__ // Bắt đầu include guard với tên của dự án
#define __MY_SERVICE__ // Định nghĩa tên include guard

#property copyright "PhiLongTrading"
#property link "philong.com"

#include <TradingToys/MyStruct.mqh>

/// @brief MyService
namespace MyService
{

   // Update giá mới vào mảng theo TIMEFRAME
   bool UpdateDataCandle(string symbol, ENUM_TIMEFRAMES timeFrame, int pos, int count, MqlRates &arrResult[])
   {
      int check = -1;
      switch (timeFrame)
      {
      case PERIOD_M1:
         check = CopyRates(symbol, timeFrame, pos, count, arrResult);
         break;
      case PERIOD_M3:
         check = CopyRates(symbol, timeFrame, pos, count, arrResult);
         break;
      case PERIOD_M5:
         check = CopyRates(symbol, timeFrame, pos, count, arrResult);
         break;
      case PERIOD_M15:
         check = CopyRates(symbol, timeFrame, pos, count, arrResult);
         break;
      case PERIOD_M30:
         check = CopyRates(symbol, timeFrame, pos, count, arrResult);
         break;
      case PERIOD_H1:
         check = CopyRates(symbol, timeFrame, pos, count, arrResult);
         break;
      case PERIOD_H4:
         check = CopyRates(symbol, timeFrame, pos, count, arrResult);
         break;
      case PERIOD_D1:
         check = CopyRates(symbol, timeFrame, pos, count, arrResult);
         break;
      case PERIOD_W1:
         check = CopyRates(symbol, timeFrame, pos, count, arrResult);
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
      while (!IsNewMinute(1, result))
      {
      }
      // Thiết lập chu kỳ gọi hàm OnTimer() --60 giây
      EventSetTimer(60);
      SetCloseTimeFrame(tfClose);
      Print("Bắt đầu thiết lập thời gian");
   }

   // Trả về true nếu giây là 1
   bool IsNewMinute(int sec, MqlDateTime &result)
   {
      // Lấy time hiện tại
      TimeToStruct(TimeCurrent(), result);
      // Check nếu giây = 1 có nghĩa là phút mới (1 là để cho chắc chắn)
      if (result.sec == sec)
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
      TimeToStruct(iTime(_Symbol, PERIOD_M3, 0), m3);   // Thời gian mở cửa của nến M3 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_M5, 0), m5);   // Thời gian mở cửa của nến M5 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_M15, 0), m15); // Thời gian mở cửa của nến M15 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_M30, 0), m30); // Thời gian mở cửa của nến M30 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_H1, 0), h1);   // Thời gian mở cửa của nến H1 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_H4, 0), h4);   // Thời gian mở cửa của nến H4 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_D1, 0), d1);   // Thời gian mở cửa của nến D1 hiện tại
      TimeToStruct(iTime(_Symbol, PERIOD_W1, 0), w1);   // Thời gian mở cửa của nến W1 hiện tại
      TimeToStruct(TimeCurrent(), now);                 // Thời gian hiện tại
      // Thời gian đóng nến = Thời gian mặc định nến - (thời gian đã chạy được trên nến hiện tại)
      tfClose.M3 = 3 - (now.min - m3.min);
      tfClose.M5 = 5 - (now.min - m5.min);
      tfClose.M15 = 15 - (now.min - m15.min);
      tfClose.M30 = 30 - (now.min - m30.min);
      tfClose.H1 = 60 - (now.min - h1.min);
      tfClose.H4 = 4 - (now.hour - h4.hour);
      tfClose.D1 = 24 - (now.hour - d1.hour);
      tfClose.W1 = 7 - (now.day - w1.day);
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
      return (isClose.day_of_week == 5 && isClose.hour == 23);
   }

   // Chuyển mảng nến sang mảng High/Low
   bool ConvertToHighLowArrDemo(MqlRates &arr[], SwingInfo &arrHighLow[])
   {
      int count = ArraySize(arr);
      for (int i = 0; i < count - 1; i++) // lặp từ phần tử đầu tới phần tử "sát cuối" (n-1)
      {
         MqlRates rateCurrent = arr[i];
         MqlRates rateNext = arr[i + 1];
         if (IsBullishCandle(rateCurrent) != IsBullishCandle(rateNext)) // check 2 nến khác nhau
         {
            if (IsBullishCandle(rateCurrent)) // nến tăng => đỉnh
            {
               SwingInfo high;
               high.IsHigh = true;
               high.Shadow = MathMax(rateCurrent.high, rateNext.high);
               high.Time = rateCurrent.high > rateNext.high ? rateCurrent.time : rateNext.time;
               int newLength = ArraySize(arrHighLow) + 1;
               ArrayResize(arrHighLow, newLength);
               arrHighLow[newLength - 1] = high;
            }
            else
            { // nến giảm => đáy
               SwingInfo low;
               low.IsHigh = false;
               low.Shadow = MathMin(rateCurrent.low, rateNext.low);
               low.Time = rateCurrent.low < rateNext.low ? rateCurrent.time : rateNext.time;
               int newLength = ArraySize(arrHighLow) + 1;
               ArrayResize(arrHighLow, newLength);
               arrHighLow[newLength - 1] = low;
            }
         }
      }

      return true;
   }

   // Type1: Nến có high >= 2 nến bên cạnh là high, Nến có low <= 2 nến bên cạnh là low
   // Type2: Nến thứ 1 khác màu nến 0
   // Return mảng SwingInfo đã loại bỏ đỉnh đáy trùng sát nhau
   bool ConvertToHighLowArr(MqlRates &arr[], SwingInfo &arrHighLow[])
   {
      // Lặp ngược lại tới index 2 (để lại 2 nến đầu mảng tránh exception index)
      for (int i = ArraySize(arr) - 1; i >= 2; i--)
      {
         MqlRates candle0 = arr[i];
         MqlRates candle1 = arr[i - 1];
         MqlRates candle2 = arr[i - 2];
         int candle0Status = GetCandlesStatus(candle0);
         int candle1Status = GetCandlesStatus(candle1);
         int candle2Status = GetCandlesStatus(candle2);

         // Quy tắc xác định High/Low cho nến candles1 (type1)
         bool isHighType1 = candle1.high >= candle0.high && candle1.high >= candle2.high;
         bool isLowType1 = candle1.low <= candle0.low && candle1.low <= candle2.low;

         if (isHighType1) // Nếu là đỉnh thì add vào mảng
         {
            AddSwingToArray(true, candle0, candle1, candle2, arrHighLow);
            continue;
         }
         else // Nếu không phải đỉnh Type1 thì xác định theo Type2
         {
            if (isLowType1 && candle1Status == 1 && candle1Status != candle0Status && candle1Status != candle2Status)
            {
               AddSwingOnlyToArray(true, candle1.high >= candle0.high ? candle1 : candle0, arrHighLow);
               // triển khai thêm logic xác định đáy nếu nến hồi là 1 nến khác màu giữa 2 nến cùng màu
            }
            continue;
         }

         if (isLowType1) // Nếu không phải đáy Type1 thì xác định theo Type2
         {
            AddSwingToArray(false, candle0, candle1, candle2, arrHighLow);
            continue;
         }
         else // Nếu không phải đáy Type1 thì xác định theo Type2
         {
            if (isHighType1 && candle1Status == -1 && candle1Status != candle0Status && candle1Status != candle2Status)
            {
               AddSwingOnlyToArray(false, candle1.low <= candle0.low ? candle1 : candle0, arrHighLow);
               // triển khai thêm logic xác định đáy nếu nến hồi là 1 nến khác màu giữa 2 nến cùng màu
            }
         }
      }

      SwingClean(arrHighLow);
      return true;
   }

   // Add swing vào mảng (chọn nến thỏa mãn)
   void AddSwingToArray(bool isHigh, MqlRates &candle0, MqlRates &candle1, MqlRates &candle2, SwingInfo &arr[])
   {
      int newSize = ArraySize(arr) + 1;
      ArrayResize(arr, newSize);
      SwingInfo newSwing;
      MqlRates temp;
      if (isHigh)
         temp = candle0.high >= candle1.high ? candle0 : (candle1.high >= candle2.high ? candle1 : candle2);
      else
         temp = candle0.low <= candle1.low ? candle0 : (candle1.low <= candle2.low ? candle1 : candle2);

      newSwing.Time = temp.time;
      newSwing.IsHigh = isHigh;
      newSwing.Shadow = isHigh ? temp.high : temp.low;
      newSwing.Close = isHigh ? (temp.close >= temp.open ? temp.close : temp.open)  // đỉnh
                              : (temp.close <= temp.open ? temp.close : temp.open); // đáy
      // Gán vào cuối mảng
      arr[newSize - 1] = newSwing;
   }

   // Add swing vào mảng
   void AddSwingOnlyToArray(bool isHigh, MqlRates &candle, SwingInfo &arr[])
   {
      int newSize = ArraySize(arr) + 1;
      ArrayResize(arr, newSize);
      SwingInfo newSwing;
      newSwing.Time = candle.time;
      newSwing.IsHigh = isHigh;
      newSwing.Shadow = isHigh ? candle.high : candle.low;
      newSwing.Close = isHigh ? (candle.close >= candle.open ? candle.close : candle.open)  // đỉnh
                              : (candle.close <= candle.open ? candle.close : candle.open); // đáy
      // Gán vào cuối mảng
      arr[newSize - 1] = newSwing;
   }

   /// @brief Tìm cấu trúc giảm bị break
   /// @param arr
   /// @param currentRate
   /// @return
   bool HasBullishStructure(SwingInfo &arr[], MqlRates &currentRate)
   {
      // Kiểm tra nến mới nhất truyền vào phải là nến tăng thì mới check
      if (currentRate.open >= currentRate.close)
         return false;

      bool result = false;
      // lặp từ trái sang phải tìm đỉnh tạo đáy thấp nhất
      int lastHighIndex = -1;
      double lowest = decimal.MAX_VALUE;
      for (int i = 0; i < ArraySize(arr) - 1; i++)
      {
         SwingInfo nextSwing = arr[i + 1];
         if (!nextSwing.IsHigh && nextSwing.Shadow < lowest)
         {
            lowest = nextSwing.Shadow;
            lastHighIndex = i;
         }
      }

      // Nếu không tìm thấy đỉnh tạo đáy thấp nhất thỉ return luôn
      if (lastLowIndex == -1)
      return false;

      SwingInfo lastHigh = arr[lastHighIndex];
      // check nến hiện tại có phá vỡ đỉnh tạo đáy thấp nhất chưa
      if (currentRate.close <= lastHighIndex.Shadow)
         return false;
      /*
       * Giá đã break structure, giờ tìm có cấu trúc tăng không
       * Tìm cấu trúc tăng và giá cao hơn đỉnh tạo đáy thấp nhất
       */
      for (int j = lastHighIndex; i < ArraySize(arr) - 3; i++)
      {
         SwingInfo swingLowest = arr[j + 1];
         SwingInfo swingHigh = arr[j + 2];
         SwingInfo swingLow = arr[j + 3];
         if (swingLowest.Shadow <= swingLow.Shadow && swingHigh.Shadow < currentRate.close)
            result = true;
      }

      return result;
   }

   /// @brief Tìm cấu trúc tăng bị break
   /// @param arr
   /// @param currentRate
   /// @return
   bool HasBearishStructure(SwingInfo &arr[], MqlRates &currentRate)
   {
      // Kiểm tra nến mới nhất truyền vào phải là nến giảm thì mới check
      if (currentRate.open <= currentRate.close)
         return false;

      bool result = false;
      // lặp từ trái sang phải tìm đáy tạo đỉnh cao nhất
      int lastLowIndex = -1;
      double highest = decimal.MIN_VALUE;
      for (int i = 0; i < ArraySize(arr) - 1; i++)
      {
         SwingInfo nextSwing = arr[i + 1];
         if (nextSwing.IsHigh && nextSwing.Shadow > highest)
         {
            highest = nextSwing.Shadow;
            lastLowIndex = i;
         }
      }

      // Nếu không tìm thấy đáy tạo đỉnh cao nhất thỉ return luôn
      if (lastLowIndex == -1)
         return false;

      SwingInfo lastLow = arr[lastLowIndex];
      // check nến hiện tại có phá vỡ đỉnh tạo đáy thấp nhất chưa
      if (currentRate.close >= lastLow.Shadow)
         return false;
      /*
       * Giá đã break structure, giờ tìm có cấu trúc tăng không
       * Tìm cấu trúc tăng và giá cao hơn đỉnh tạo đáy thấp nhất
       */
      for (int j = lastLowIndex; i < ArraySize(arr) - 3; i++)
      {
         SwingInfo swingHighest = arr[j + 1];
         SwingInfo swingLow = arr[j + 2];
         SwingInfo swingHigh = arr[j + 3];
         if (swingHighest.Shadow >= swingHigh.Shadow && swingLow.Shadow > currentRate.close)
            result = true;
      }

      return result;
   }

   // Loại bỏ đỉnh đáy
   void SwingClean(SwingInfo &arr[])
   {
      int length = ArraySize(arr);
      SwingInfo arrClone[];
      ArrayResize(arrClone, length);
      ArrayCopy(arrClone, arr); // gán giá trị sang clone để lát trả về arr gốc
      ArrayFree(arr);           // reset mảng gốc
      ArrayResize(arr, length);
      int countResult = 0;
      for (int i = 0; i <= length - 2; i++) // lặp từ đầu tới phần tử sát cuối vì có vòng lặp k
      {
         for (int k = i + 1; k <= length - 1; k++)
         {
            SwingInfo result = arrClone[i];
            if (arrClone[i].IsHigh) // nếu temp là đỉnh thì tìm xem có đỉnh nào sau đó không
            {
               if (arrClone[k].IsHigh) // nếu tempK cũng là đỉnh giống tempI thì lấy cái nào có đỉnh cao hơn
               {
                  result = (result.Shadow >= arrClone[k].Shadow) ? result : arrClone[k];
               }
               else // Tới khi K khác I thì có nghĩa là lặp hết đỉnh sau đó rồi => thêm result vào mảng kết quả
               {
                  if (countResult > 0 && arr[countResult - 1].Shadow >= result.Shadow) // nếu trước đó đã tìm ra đỉnh cao nhất gần nhau thì break
                     break;
                  arr[countResult] = result;
                  countResult++;
                  break;
               }
            }
            else if (!arrClone[i].IsHigh) // nếu temp là đáy thì tìm xem có đáy nào sau đó không
            {
               if (!arrClone[k].IsHigh) // nếu tempK cũng là đáy giống tempI thì lấy cái nào có đỉnh cao hơn
               {
                  result = (result.Shadow <= arrClone[k].Shadow) ? result : arrClone[k];
               }
               else // Tới khi K khác I thì có nghĩa là lặp hết đáy sau đó rồi => thêm result vào mảng kết quả
               {
                  if (countResult > 0 && arr[countResult - 1].Shadow <= result.Shadow)
                     break;
                  arr[countResult] = result;
                  countResult++;
                  break;
               }
            }
         }
      }

      ArrayResize(arr, --countResult);
   }

   int GetCandlesStatus(MqlRates &rate)
   {
      // 1: nến tăng, 0: nến doji, -1: nến giảm
      return (rate.close > rate.open) ? 1 : ((rate.close < rate.open) ? -1 : 0);
   }

   bool IsBullishCandle(MqlRates &rate)
   {
      return rate.open > rate.close;
   }

}

#endif