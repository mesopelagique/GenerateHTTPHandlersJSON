#DECLARE($event : Integer)
Case of 
	: ($event=On after host database startup:K74:4)
		GenerateHTTPHandlers
End case 