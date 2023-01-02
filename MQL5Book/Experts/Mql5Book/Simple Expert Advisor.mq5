//+------------------------------------------------------------------+
//| 														  Simple Expert Advisor |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

#property copyright "Andrew Young"
#property link      "http://www.expertadvisorbook.com"
#property description "A simple trading system that opens an order when the close price crosses a moving average line. No external functions or classes."

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/


// Input variables
input double TradeVolume=0.1;
input int StopLoss=1000;
input int TakeProfit=1000;
input int MAPeriod=10;


// Global variables 
bool glBuyPlaced, glSellPlaced;


// OnTick() event handler
void OnTick()
{
	
	// Trade structures
	MqlTradeRequest request;
	MqlTradeResult result;
	ZeroMemory(request);

	
	// Moving average
	double ma[];
	ArraySetAsSeries(ma,true);
	
	int maHandle=iMA(_Symbol,0,MAPeriod,MODE_SMA,0,PRICE_CLOSE);
   CopyBuffer(maHandle,0,0,1,ma);
   
   
   // Close price
   double close[];
   ArraySetAsSeries(close,true);
   CopyClose(_Symbol,0,0,1,close);
   
   
   // Current position information
   bool openPosition = PositionSelect(_Symbol);
   long positionType = PositionGetInteger(POSITION_TYPE);
   
   double currentVolume = 0;
   if(openPosition == true) currentVolume = PositionGetDouble(POSITION_VOLUME);
   
   
   // Open buy market order
   if(close[0] > ma[0] && glBuyPlaced == false && (positionType != POSITION_TYPE_BUY || openPosition == false))
   {
   	request.action = TRADE_ACTION_DEAL;
		request.type = ORDER_TYPE_BUY;
		request.symbol = _Symbol;
		request.volume = TradeVolume + currentVolume;
		request.price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
		request.sl = 0;
		request.tp = 0;
		request.deviation = 50;
		
		bool sent = OrderSend(request,result);
		
		// Modify SL/TP
		if(result.retcode == TRADE_RETCODE_PLACED || result.retcode == TRADE_RETCODE_DONE)
		{
			request.action = TRADE_ACTION_SLTP;
			
			PositionSelect(_Symbol);
			double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
	
			if(StopLoss > 0) request.sl = positionOpenPrice - (StopLoss * _Point);
			if(TakeProfit > 0) request.tp = positionOpenPrice + (TakeProfit * _Point);
			
			if(request.sl > 0 && request.tp > 0) sent = OrderSend(request,result);
			
			glBuyPlaced = true;
			glSellPlaced = false;
		} 
   }
   
   
   // Open sell market order
   else if(close[0] < ma[0] && glSellPlaced == false && positionType != POSITION_TYPE_SELL)
   {
   	request.action = TRADE_ACTION_DEAL;
		request.type = ORDER_TYPE_SELL;
		request.symbol = _Symbol;
		request.volume = TradeVolume + currentVolume;
		request.price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
		request.sl = 0;
		request.tp = 0;
		request.deviation = 50;
		
		bool sent = OrderSend(request,result);
		
		// Modify SL/TP
		if((result.retcode == TRADE_RETCODE_PLACED || result.retcode == TRADE_RETCODE_DONE) && (StopLoss > 0 || TakeProfit > 0))
		{
			request.action = TRADE_ACTION_SLTP;
			
			PositionSelect(_Symbol);
			double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
	
			if(StopLoss > 0) request.sl = positionOpenPrice + (StopLoss * _Point);
			if(TakeProfit > 0) request.tp = positionOpenPrice - (TakeProfit * _Point);
			
			if(request.sl > 0 && request.tp > 0) sent = OrderSend(request,result);
			
			glBuyPlaced = false;
			glSellPlaced = true;
		} 
   } 
}

