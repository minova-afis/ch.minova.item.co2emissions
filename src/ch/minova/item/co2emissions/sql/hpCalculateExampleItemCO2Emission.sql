alter procedure dbo.hpCalculateExampleItemCO2Emission (
	@KeyLong int output
	@CalorificValueKG float output, 
	@CalorificValueT float output, 
	@HeatingRelatedEmissionValueKG float output, 
	@HeatingRelatedEmissionValueT float output, 
	@PriceCertificate money output, 
	@ExampleQty float output, 
	@CalculatedEmissionOfDelivery float output, 
	@CalculatedPricePartCO2Costs float output, 
	@EnergyOfDelivery float output
)
with encryption as
	declare @Density float
	select @Density = DefaultDensity from tItem where KeyLong = @KeyLong
	
	
	if(@Density is null)
	begin 
		raiserror('ADO | 30 | msg.NoDefaultDenisty | Es fehlen die Standarddichte für dieses Produkt!',16, 1)
	end 
	
	if((@CalorificValueKG is null and @CalorificValueT is null) or (@HeatingRelatedEmissionValueKG is null and @HeatingRelatedEmissionValueT is null) or @PriceCertificate is null)
	begin
		raiserror('ADO | 30 | msg.NoValidItemCO2EmissionValues | Es fehlen Emissionsbezogene Stammdaten für dieses Produkt!',16, 1)
	end 
	
	declare @GJ float = 277,778 -- kWh
	
	if(@HeatingRelatedEmissionValueKG is not null and @HeatingRelatedEmissionValueT is null)
	begin
		set @HeatingRelatedEmissionValueT = ROUND(@GJ * @HeatingRelatedEmissionValueKG / 1000, 5)
	end 
	
	if(HeatingRelatedEmissionValueKG is null and @HeatingRelatedEmissionValueT is not null)
	begin
		set @HeatingRelatedEmissionValueKG = ROUND(@HeatingRelatedEmissionValueT * 1000 / @GJ, 5)
	end 
	
	if(@CalorificValueKG is not null and @CalorificValueT is null)
	begin
		set @CalorificValueT = ROUND(CalorificValueKG * 1000 / @GJ, 5)
	end 
	
	if(@CalorificValueT is not null and @CalorificValueKG is null)
	begin
		set @CalorificValueKG = ROUND(@CalorificValueT /1000 * @GJ, 5)
	end
	
	-- Brennstoffemissionen der Lieferung
	set @CalculatedEmissionOfDelivery = Round(@CalorificValueT * @HeatingRelatedEmissionValueT * @Density * @ExampleQty, 3)
	
	-- Preisbestandteil CO2-Kosten (inklusive der Mehrwertsteuer)
	set @CalculatedPricePartCO2Costs = ROUND(@CalculatedEmissionOfDelivery * @PriceCertificate * 1.19,3)
	
	-- Energiegehalt der Lieferung
	set @EnergyOfDelivery = ROUND(@CalorificValueT * @Density * @ExampleQty, 3)
