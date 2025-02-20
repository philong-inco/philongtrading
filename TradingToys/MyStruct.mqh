#ifndef __MY_STRUCT__
#define __MY_STRUCT__



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
   bool IsHigh;
   double Price;
   datetime Time;
}

#endif
