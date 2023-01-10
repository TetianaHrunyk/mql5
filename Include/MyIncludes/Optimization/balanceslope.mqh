//=====================================================================
//	Library for calculation of the regression line for the balance curve.
//=====================================================================

//---------------------------------------------------------------------
#property copyright 	"Dima S., 2011г."
#property link      	"dimascub@mail.com"
//---------------------------------------------------------------------

//=====================================================================
//	Operations with balance history:
//=====================================================================
class TBalanceHistory
  {
private:
   int               real_trades;                                     // actual number of performed trades

public:
   string            trade_symbol;                                    // operations with work symbol

protected:
   //	"Raw" arrays:
   double            org_datetime_array[];                            // date/time of trade
   double            org_result_array[];                              // result of trade

                                                                      //	Arrays with data grouped by time:
   double            group_datetime_array[];                          // date/time of trdade
   double            group_result_array[];                            // result of trade

   double            last_result_array[];                             // array for results of last trades (points on the OY axis)
   double last_datetime_array[ ];                                     // array for storing time of last trades (points on the OX axis)

private:
   void              SortMasterSlaveArray(double &_m[],double &_s[]); // synchronous descending sorting of two arrays

public:
   void              SetTradeSymbol(string _symbol);                  // set/modify work symbol
   string            GetTradeSymbol();                                // get work symbol
   int               GetRealTrades();                                 // get the number of last trades
   int               GetTradeResultsArray();                          // get results of last trades

public:
                     TBalanceHistory(string _symbol);                 // constructor
   void             ~TBalanceHistory();                               // destructor
  };
//---------------------------------------------------------------------
//	Constructor:
//---------------------------------------------------------------------
void  TBalanceHistory::TBalanceHistory(string _symbol)
   :
trade_symbol(_symbol)
  {
  }
//---------------------------------------------------------------------
//	Destructor:
//---------------------------------------------------------------------
void  TBalanceHistory::~TBalanceHistory()
  {
  }
//---------------------------------------------------------------------
//	Get amount of last trades:
//---------------------------------------------------------------------
int  TBalanceHistory::GetRealTrades()
  {
   return(this.real_trades);
  }
//---------------------------------------------------------------------
//	Set/change work symbol:
//---------------------------------------------------------------------
void  TBalanceHistory::SetTradeSymbol(string _symbol)
  {
   this.trade_symbol=_symbol;
  }
//---------------------------------------------------------------------
//	Get work symbol:
//---------------------------------------------------------------------
string  TBalanceHistory::GetTradeSymbol()
  {
   return(this.trade_symbol);
  }
//---------------------------------------------------------------------
//	Synchronous descending right-to-left sorting of two arrays:
//---------------------------------------------------------------------
void  TBalanceHistory::SortMasterSlaveArray(double &_master[],double &_slave[])
  {
   int            size=ArraySize(_master);
   if(size!=ArraySize(_slave))
     {
      return;
     }

   double      temp_m=0.0;
   double      temp_s;

   for(int i=1;  i<=size; i++)
     {
      for(int j=0;  j<size-i;  j++)
        {
         //	If the left element is less than the right one, change their places:
         if(_master[j]<_master[j+1])
           {
            temp_m=_master[j];
            _master[j]=_master[j+1];
            _master[j+1]=temp_m;

            temp_s=_slave[j];
            _slave[j]=_slave[j+1];
            _slave[j+1]=temp_s;
           }
        }
     }
  }
//---------------------------------------------------------------------
//	Get results of all trades to arrays:
//---------------------------------------------------------------------
//	- returns the number of read trades;
//---------------------------------------------------------------------
int  TBalanceHistory::GetTradeResultsArray()
  {
   int            index,count;
   long         deal_type,deal_entry;
   int            deal_close_time,current_time;
   ulong         deal_ticket;                                                                  // deal ticket
   double      trade_result;
   string      deal_symbol;

   this.real_trades=0;

//	If a work symbol is not specified, don't do anything:
   if(this.trade_symbol==NULL)
     {
      return(0);
     }

//	Request the history of deals and orders from the specified time to the current moment:
   if(HistorySelect(0,TimeCurrent())!=true)
     {
      return(0);
     }

//	Count number of trades:
   count=HistoryDealsTotal();

//	If there are less trades in history than needed, then exit:
   if(count<2)
     {
      return(0);
     }

//	If needed, adjust the size of "raw" arrays:
   if(( ArraySize(this.org_datetime_array))!=count)
     {
      ArrayResize( this.org_datetime_array, count );
      ArrayResize( this.org_result_array, count );
     }

//	Fill the "raw" array from the base of trades:
   for(index=count-1; index>=0; index--)
     {
      deal_ticket=HistoryDealGetTicket(index);

      //	If they are not closed trades, don't go further:
      deal_entry=HistoryDealGetInteger(deal_ticket,DEAL_ENTRY);
      if(deal_entry!=DEAL_ENTRY_OUT)
        {
         continue;
        }

      //	Check symbol of deal:
      deal_symbol=HistoryDealGetString(deal_ticket,DEAL_SYMBOL);
      if(deal_symbol!=this.trade_symbol)
        {
         continue;
        }

      //	Check deal type:
      deal_type=HistoryDealGetInteger(deal_ticket,DEAL_TYPE);
      if(deal_type!=DEAL_TYPE_BUY && deal_type!=DEAL_TYPE_SELL)
        {
         continue;
        }

      //	Время закрытия сделки:
      deal_close_time=(int)HistoryDealGetInteger(deal_ticket,DEAL_TIME);

      //	Thus, we can read another trade:
      this.org_datetime_array[this.real_trades]=(double)(deal_close_time/60);
      this.org_result_array[this.real_trades]=HistoryDealGetDouble(deal_ticket,DEAL_PROFIT)/HistoryDealGetDouble(deal_ticket,DEAL_VOLUME);
      this.real_trades++;
     }

//	If there are less trades than required for drawing the regression line, then exit:
   if(this.real_trades<2)
     {
      return(0);
     }
   count=this.real_trades;

//	Sort the "raw" array by date/time of closing of orders:
   SortMasterSlaveArray(this.org_datetime_array,this.org_result_array);

//	If needed, adjust the size of group arrays:
   if(( ArraySize(this.group_datetime_array))!=count)
     {
      ArrayResize( this.group_datetime_array, count );
      ArrayResize( this.group_result_array, count );
     }
   ArrayInitialize( this.group_datetime_array, 0.0 );
   ArrayInitialize( this.group_result_array, 0.0 );

//	Fill the output array with grouped information (group by the identity of date/time closing positions):
   this.real_trades=0;
   for(index=0; index<count; index++)
     {
      //	Get another trade:
      deal_close_time=(int)this.org_datetime_array[index];
      trade_result=this.org_result_array[index];

      //	Now check if the same time already exists in the output array:
      current_time=(int)this.group_datetime_array[this.real_trades];
      if(current_time>0 && (int)MathAbs(current_time-deal_close_time)>0)
        {
         this.real_trades++;                                    // move the pointer to the next element
         this.group_result_array[this.real_trades]=trade_result;
         this.group_datetime_array[this.real_trades]=deal_close_time;
        }
      else
        {
         this.group_result_array[this.real_trades]+=trade_result;
         this.group_datetime_array[this.real_trades]=deal_close_time;
        }
     }
   this.real_trades++;                                          // now this is the number of non-repeated elements

                                                                //	If there are less trades than required for drawing the regression line, then exit:
   if(this.real_trades<2)
     {
      return(0);
     }

   if(ArraySize(this.last_result_array)!=this.real_trades)
     {
      ArrayResize( this.last_result_array, this.real_trades );
      ArrayResize( this.last_datetime_array, this.real_trades );
     }

//	Write the accumulated information to output arrays with the reversed indexation:
   for(index=0; index<this.real_trades; index++)
     {
      this.last_result_array[this.real_trades-1-index]=this.group_result_array[index];
      this.last_datetime_array[this.real_trades-1-index]=this.group_datetime_array[index];
     }

//	Replace the results of single trades with the growing total amount in the output array:
   for(index=1; index<this.real_trades; index++)
     {
      this.last_result_array[index]+=this.last_result_array[index-1];
     }

   return(this.real_trades);
  }
//=====================================================================
//	Operations with balance curve:
//=====================================================================
class TBalanceSlope : public TBalanceHistory
  {
protected:
   double            current_slope;                                   // current slope angle of the balance curve
   double            current_sko;                                     // max. value of standard deviation relatively to the regression line

private:
   double            LR_koeff_A,LR_koeff_B;                           // coefficient for the equation of the regression line
   double            LR_points_array[];                               // array of points of the linear regression line

private:
   void              CalcLR(double &X[],double &Y[]);                 // calculate the equation of the regression line

public:
   double            CalcSlope();                                     // calculate the slope angle
   double            GetCurrentSlope();                               // get the current slope angle
   double            GetCurrentSKO();                                 // get the current value of standard deviation

public:
   void              TBalanceSlope(string _symbol);                   // constructor
   void             ~TBalanceSlope();                                 // destructor
  };
//---------------------------------------------------------------------
//	Constructor:
//---------------------------------------------------------------------
void  TBalanceSlope::TBalanceSlope(string _symbol)
   :
TBalanceHistory(_symbol)
  {
   this.current_slope=0.0;
   this.current_sko=0.0;
  }
//---------------------------------------------------------------------
//	Destructor:
//---------------------------------------------------------------------
void  TBalanceSlope::~TBalanceSlope()
  {
  }
//---------------------------------------------------------------------
//	Get current angle of slope:
//---------------------------------------------------------------------
double  TBalanceSlope::GetCurrentSlope()
  {
   return(this.current_slope);
  }
//---------------------------------------------------------------------
//	Get the current value of Standard Deviation:
//---------------------------------------------------------------------
double  TBalanceSlope::GetCurrentSKO()
  {
   return(this.current_sko);
  }
//---------------------------------------------------------------------
//	Calculate the equation of straight-line regression:
//---------------------------------------------------------------------
//	Author: Sergey Privalov aka Prival,  Skype: privalov-sv
//---------------------------------------------------------------------
//	input parameters:
//		X[ ] - array of values of the number series along the X axis;
//		Y[ ] - array of values of the number series along the Y axis;
//---------------------------------------------------------------------
void  TBalanceSlope::CalcLR(double &X[],double &Y[])
  {
   double      mo_X=0,mo_Y=0,var_0=0,var_1=0;
   int            i;
   int            size=ArraySize(X);
   double      nmb=(double)size;
   double      temp_y,temp_x;

//	If the number of points is less than two, the straight line cannot be calculated:
   if(size<2)
     {
      return;
     }

   for(i=0; i<size; i++)
     {
      mo_X += X[ i ];
      mo_Y += Y[ i ];
     }
   mo_X /= nmb;
   mo_Y /= nmb;

   for(i=0; i<size; i++)
     {
      temp_x = X[ i ] - mo_X;
      temp_y = Y[ i ] - mo_Y;

      ////		var_0 += ( X[ i ] - mo_X ) * ( Y[ i ] - mo_Y );
      ////		var_1 += ( X[ i ] - mo_X ) * ( X[ i ] - mo_X );

      var_0 += temp_x * temp_y;
      var_1 += temp_x * temp_x;

      this.current_sko+=temp_y*temp_y;
     }

   this.current_sko=MathSqrt(this.current_sko)/nmb;

//	Value of the A coefficient:
   if(var_1!=0.0)
     {
      this.LR_koeff_A=var_0/var_1;
     }
   else
     {
      this.LR_koeff_A=0.0;
     }

//	Value of the B coefficient:
   this.LR_koeff_B=mo_Y-this.LR_koeff_A*mo_X;

//	Fill the array of points which lie on the straight line of regression:
   ArrayResize(this.LR_points_array,size);
   for(i=0; i<size; i++)
     {
      this.LR_points_array[i]=this.LR_koeff_A*X[i]+this.LR_koeff_B;
     }
  }
//---------------------------------------------------------------------
//	Calculate slope angle:
//---------------------------------------------------------------------
double  TBalanceSlope::CalcSlope()
  {
//	Get the result of trading from the history of trades:
   int         nmb=this.GetTradeResultsArray();
   if(nmb<2)
     {
      return(0.0);
     }

//	Calculate the regression line on the basis of results of the last trades:
   this.CalcLR( last_datetime_array, last_result_array );
   this.current_slope=this.LR_koeff_A;

   return(this.current_slope);
  }
//---------------------------------------------------------------------
