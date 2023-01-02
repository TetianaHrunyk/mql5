//+------------------------------------------------------------------+
//| 							              Simple Expert Advisor (Hedging)|
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

#property copyright "Andrew Young"
#property link      "http://www.expertadvisorbook.com"
#property description "Same as Simple Expert Advisor, but using the functions and classes defined in the include files."

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
input int MAPeriod = 10;


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
	
	int maHandle=iMA(_Symbol,0,MAPeriod,MODE_LWMA,0,PRICE_CLOSE);
	CopyBuffer(maHandle,0,0,1,ma);

	// Close price
	double close[];
	ArraySetAsSeries(close,true);
	CopyClose(_Symbol,0,0,1,close);
	
	
	// Get current market orders
	ulong buyTicket = 0, sellTicket = 0;
	for(int i = 0; i < PositionsTotal(); i++)
	{
	   ulong ticket = PositionGetTicket(i);
	   PositionSelectByTicket(ticket);
	   
	   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
	   {
	      buyTicket = ticket;
	      glBuyPlaced = true;
	   }
	   else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
	   {
	      sellTicket = ticket;
	      glSellPlaced = true;
	   }
	}
   
   
   // Open buy market order
   if(close[0] > ma[0] && glBuyPlaced == false)
   {
   	// Close sell order
   	if(sellTicket > 0)
   	{
   	   PositionSelectByTicket(sellTicket);
   	   
   	   request.action = TRADE_ACTION_DEAL;
   	   request.type = ORDER_TYPE_BUY;
   	   request.symbol = _Symbol;
	      request.position = sellTicket;
	      request.volume = PositionGetDouble(POSITION_VOLUME);
			request.price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
			request.deviation = 50;
			
			bool sent = OrderSend(request, result);
   	}
   	
   	// Open buy order
   	request.action = TRADE_ACTION_DEAL;
		request.type = ORDER_TYPE_BUY;
		request.symbol = _Symbol;
		request.position = 0;
		request.volume = TradeVolume;
		request.price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
		request.sl = 0;
		request.tp = 0;
		request.deviation = 50;
		
		bool sent = OrderSend(request,result);
		
		// Modify SL/TP
		if(result.retcode == TRADE_RETCODE_PLACED || result.retcode == TRADE_RETCODE_DONE)
		{
			request.action = TRADE_ACTION_SLTP;
			request.position = result.order;
			
			PositionSelectByTicket(result.order);
			double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
	
			if(StopLoss > 0) request.sl = positionOpenPrice - (StopLoss * _Point);
			if(TakeProfit > 0) request.tp = positionOpenPrice + (TakeProfit * _Point);
			
			if(request.sl > 0 && request.tp > 0) sent = OrderSend(request,result);
			
			glSellPlaced = false;
		} 
   }
   
   
   // Open sell market order
   else if(close[0] < ma[0] && glSellPlaced == false)
   {
   	// Close buy order
   	if(buyTicket > 0)
   	{
   	   PositionSelectByTicket(buyTicket);
   	   
   	   request.action = TRADE_ACTION_DEAL;
   	   request.type = ORDER_TYPE_SELL;
   	   request.symbol = _Symbol;
	      request.position = buyTicket;
	      request.volume = PositionGetDouble(POSITION_VOLUME);
			request.price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
			request.deviation = 50;
			
			bool sent = OrderSend(request, result);
   	}
   	
   	// Open sell order
   	request.action = TRADE_ACTION_DEAL;
		request.type = ORDER_TYPE_SELL;
		request.symbol = _Symbol;
		request.position = 0;
		request.volume = TradeVolume;
		request.price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
		request.sl = 0;
		request.tp = 0;
		request.deviation = 50;
		
		bool sent = OrderSend(request,result);
		
		// Modify SL/TP
		if(result.retcode == TRADE_RETCODE_PLACED || result.retcode == TRADE_RETCODE_DONE)
		{
			request.action = TRADE_ACTION_SLTP;
			request.position = result.order;
			
			PositionSelectByTicket(result.order);
			double positionOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
			
			if(StopLoss > 0) request.sl = positionOpenPrice + (StopLoss * _Point);
			if(TakeProfit > 0) request.tp = positionOpenPrice - (TakeProfit * _Point);
			
			if(request.sl > 0 && request.tp > 0) sent = OrderSend(request,result);
			
			glBuyPlaced = false;
		} 
   } 
    
}

