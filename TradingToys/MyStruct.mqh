#ifndef __MY_STRUCT__
#define __MY_STRUCT__


/// @brief Dữ liệu thời gian còn lại theo TimeFrame
struct CloseCandleInfo
{
   int M3;
   int M5;
   int M15;
   int M30;
   int H1;
   int H4;
   int D1;
   int W1;
};

struct SwingInfo
{
   bool IsHigh;   // True: High - Flase: Low
   double Shadow; // râu nến
   double Close;  // Giá đóng cửa
   datetime Time; // Time
};

#endif
