//+------------------------------------------------------------------+
//|                                     Moving Average Cross Hedging |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

#property copyright "Andrew Young"
#property link      "http://www.expertadvisorbook.com"
#property description "A dual moving average cross for use on hedging accounts"

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/


// Trade (hedging)
#include <Mql5Book\TradeHedge.mqh>
CTradeHedge Trade;

// Money management
#include <Mql5Book\MoneyManagement.mqh>

// Timer
#include <Mql5Book\Timer.mqh>
CNewBar NewBar;

// Indicators 
#include <Mql5Book\Indicators.mqh>
CiMA FastMA;
CiMA SlowMA;


//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+

input ulong Slippage = 3;
input bool TradeOnNewBar = true;
input int MagicNumber = 1;

sinput string MM; 	// Money Management
input bool UseMoneyManagement = true;
input double RiskPercent = 2;
input double FixedVolume = 0.1;

sinput string SL; 	// Stop Loss & Take Profit
input int StopLoss = 0;
input int TakeProfit = 0;

sinput string FaMA;	// Fast MA
input int FastMAPeriod = 10;
input ENUM_MA_METHOD FastMAMethod = 0;
input int FastMAShift = 0;
input ENUM_APPLIED_PRICE FastMAPrice = PRICE_CLOSE;

sinput string SlMA;	// Slow MA
input int SlowMAPeriod = 20;
input ENUM_MA_METHOD SlowMAMethod = 0;
input int SlowMAShift = 0;
input ENUM_APPLIED_PRICE SlowMAPrice = PRICE_CLOSE;



//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+

// Store order tickets
ulong glBuyTicket, glSellTicket;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
	FastMA.Init(_Symbol,_Period,FastMAPeriod,FastMAShift,FastMAMethod,FastMAPrice);
	SlowMA.Init(_Symbol,_Period,SlowMAPeriod,SlowMAShift,SlowMAMethod,SlowMAPrice);
	
	// Set deviation and magic number
	Trade.Deviation(Slippage);
	Trade.MagicNumber(MagicNumber);
	
   return(0);
}



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{

	// Check for new bar
	bool newBar = true;
	int barShift = 0;
	
	if(TradeOnNewBar == true) 
	{
		newBar = NewBar.CheckNewBar(_Symbol,_Period);
		barShift = 1;
	}
	
	
	// Order placement
	if(newBar == true)
	{
		// Money management
		double tradeSize;
		if(UseMoneyManagement == true) tradeSize = MoneyManagement(_Symbol,FixedVolume,RiskPercent,StopLoss);
		else tradeSize = VerifyVolume(_Symbol,FixedVolume);
		
		
		// Open buy order
		if(FastMA.Main(barShift) > SlowMA.Main(barShift) && glBuyTicket == 0)
		{
			// Close current position
			Trade.Close(glSellTicket);
			glSellTicket = 0;
			
			// Open buy position
			glBuyTicket = Trade.Buy(_Symbol,tradeSize);
		
			if(glBuyTicket > 0)  
			{
				// Select order by ticket and set SL/TP
				double openPrice = PositionOpenPrice(glBuyTicket);
				
				double buyStop = BuyStopLoss(_Symbol,StopLoss,openPrice);
				if(buyStop > 0) AdjustBelowStopLevel(_Symbol,buyStop);
				
				double buyProfit = BuyTakeProfit(_Symbol,TakeProfit,openPrice);
				if(buyProfit > 0) AdjustAboveStopLevel(_Symbol,buyProfit);
				
				if(buyStop > 0 || buyProfit > 0) Trade.ModifyPosition(glBuyTicket,buyStop,buyProfit);
			} 
		}
		
		
		// Open sell order
		if(FastMA.Main(barShift) < SlowMA.Main(barShift) && glSellTicket == 0)
		{
			Trade.Close(glBuyTicket);
			glBuyTicket = 0;
			
			glSellTicket = Trade.Sell(_Symbol,tradeSize);
			
			if(glSellTicket > 0)
			{
				double openPrice = PositionOpenPrice(glSellTicket);
				
				double sellStop = SellStopLoss(_Symbol,StopLoss,openPrice);
				if(sellStop > 0) sellStop = AdjustAboveStopLevel(_Symbol,sellStop);
				
				double sellProfit = SellTakeProfit(_Symbol,TakeProfit,openPrice);
				if(sellProfit > 0) sellProfit = AdjustBelowStopLevel(_Symbol,sellProfit);
				
				if(sellStop > 0 || sellProfit > 0) Trade.ModifyPosition(glSellTicket,sellStop,sellProfit);
			} 
		}
		
		
	} // Order placement end

}

