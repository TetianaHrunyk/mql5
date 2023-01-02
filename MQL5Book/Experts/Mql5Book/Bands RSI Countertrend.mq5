//+------------------------------------------------------------------+
//|                                           Bands/RSI CounterTrend |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

#property copyright "Andrew Young"
#property link      "http://www.expertadvisorbook.com"
#property description "A counter-trend trading system using Bollinger Bands and RSI"

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/


// Trade
#include <Mql5Book\Trade.mqh>
CTrade Trade;

// Price
#include <Mql5Book\Price.mqh>
CBars Bar;

// Money management
#include <Mql5Book\MoneyManagement.mqh>

// Trailing stops
#include <Mql5Book\TrailingStops.mqh>
CTrailing Trail;

// Timer
#include <Mql5Book\Timer.mqh>
CTimer Timer;
CNewBar NewBar;

// Indicators 
#include <Mql5Book\Indicators.mqh>
CiBollinger Bands;
CiRSI RSI;


//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+

input ulong Slippage = 3;
input bool TradeOnNewBar = true;

sinput string MM; 	// Money Management
input bool UseMoneyManagement = true;
input double RiskPercent = 2;
input double FixedVolume = 0.1;

sinput string SL; 	// Stop Loss & Take Profit
input int StopLoss = 0;
input int TakeProfit = 0;

sinput string TS;		// Trailing Stop
input bool UseTrailingStop = false;
input int TrailingStop = 0;
input int MinimumProfit = 0;
input int Step = 0; 

sinput string BE;		// Break Even
input bool UseBreakEven = false;
input int BreakEvenProfit = 0;
input int LockProfit = 0;

sinput string BB;		// Bollinger Bands
input int BandsPeriod = 20;
input int BandsShift = 0;
input double BandsDeviation = 2;
input ENUM_APPLIED_PRICE BandsPrice = PRICE_CLOSE; 

sinput string RS;	// RSI
input int RSIPeriod = 8;
input ENUM_APPLIED_PRICE RSIPrice = PRICE_CLOSE;

sinput string TI; 	// Timer
input bool UseTimer = false;
input int StartHour = 0;
input int StartMinute = 0;
input int EndHour = 0;
input int EndMinute = 0;
input bool UseLocalTime = false;



//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+

bool glBuyPlaced, glSellPlaced;

enum Signal
{
	SIGNAL_BUY,
	SIGNAL_SELL,
	SIGNAL_NONE,
};

Signal glSignal;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
	
	Bands.Init(_Symbol,_Period,BandsPeriod,BandsShift,BandsDeviation,BandsPrice);
	RSI.Init(_Symbol,_Period,RSIPeriod,RSIPrice);
	
	Trade.Deviation(Slippage);
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
	
	
	// Timer
	bool timerOn = true;
	if(UseTimer == true)
	{
		timerOn = Timer.DailyTimer(StartHour,StartMinute,EndHour,EndMinute,UseLocalTime);
	}
	
	
	// Update prices
	Bar.Update(_Symbol,_Period);
	
	
	// Order placement
	if(newBar == true && timerOn == true)
	{
		
		// Money management
		double tradeSize;
		if(UseMoneyManagement == true) tradeSize = MoneyManagement(_Symbol,FixedVolume,RiskPercent,StopLoss);
		else tradeSize = VerifyVolume(_Symbol,FixedVolume);
		
		
		if(Bar.Close(barShift) < Bands.Lower(barShift) && RSI.Main(barShift) < 30) glSignal = SIGNAL_BUY;
		else if(Bar.Close(barShift) > Bands.Upper(barShift) && RSI.Main(barShift) > 70) glSignal = SIGNAL_SELL;
		
		
		// Open buy order
		if(glSignal == SIGNAL_BUY && Bar.Close(barShift) > Bands.Lower(barShift) && Bar.Close(barShift+1) <= Bands.Lower(barShift+1)) 
		{
			glBuyPlaced = Trade.Buy(_Symbol,tradeSize);
		
			if(glBuyPlaced == true)  
			{
				double openPrice = PositionOpenPrice(_Symbol);
				
				double buyStop = BuyStopLoss(_Symbol,StopLoss,openPrice);
				if(buyStop > 0) AdjustBelowStopLevel(_Symbol,buyStop);
				
				double buyProfit = BuyTakeProfit(_Symbol,TakeProfit,openPrice);
				if(buyProfit > 0) AdjustAboveStopLevel(_Symbol,buyProfit);
				
				if(buyStop > 0 || buyProfit > 0) Trade.ModifyPosition(_Symbol,buyStop,buyProfit);
				
				glSignal = SIGNAL_NONE;
			} 
		}
		
		
		// Open sell order
		if(glSignal == SIGNAL_SELL && Bar.Close(barShift) < Bands.Upper(barShift) && Bar.Close(barShift+1) >= Bands.Upper(barShift+1)) 
		{
			glSellPlaced = Trade.Sell(_Symbol,tradeSize);
			
			if(glSellPlaced == true)
			{
				double openPrice = PositionOpenPrice(_Symbol);
				
				double sellStop = SellStopLoss(_Symbol,StopLoss,openPrice);
				if(sellStop > 0) sellStop = AdjustAboveStopLevel(_Symbol,sellStop);
				
				double sellProfit = SellTakeProfit(_Symbol,TakeProfit,openPrice);
				if(sellProfit > 0) sellProfit = AdjustBelowStopLevel(_Symbol,sellProfit);
				
				if(sellStop > 0 || sellProfit > 0) Trade.ModifyPosition(_Symbol,sellStop,sellProfit);
				
				glSignal = SIGNAL_NONE;
			} 
		}
		
	}	// Order placement end
	
	
	// Break even
	if(UseBreakEven == true && PositionType(_Symbol) != -1)
	{
		Trail.BreakEven(_Symbol,BreakEvenProfit,LockProfit);
	}
	
	
	// Trailing stop
	if(UseTrailingStop == true && PositionType(_Symbol) != -1)
	{
		Trail.TrailingStop(_Symbol,TrailingStop,MinimumProfit,Step);
	}


}


