--
-- For more information on config.lua see the Corona SDK Project Configuration Guide at:
-- https://docs.coronalabs.com/guide/basics/configSettings
--

application =
{
	content =
	{
		width = 320,
		height = 480,
		scale = "letterBox",
		fps = 60,
		imageSuffix =
	        {
							["@2x"] = 2,
	            ["@3x"] = 3
	        }
	},
	license =
{
		google =
		{
				key = "[YOUR_KEY_HERE]",
		},
},
}
