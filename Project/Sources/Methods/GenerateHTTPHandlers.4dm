//%attributes = {"shared":true}
var $handlers:=[]

var $classFolder:=Folder:C1567(fk database folder:K87:14; *).folder("Project/Sources/Classes")
var $classFile : 4D:C1709.File
For each ($classFile; $classFolder.files().filter(Formula:C1597($1.extension="4dm")))
	
	var $classContent:=$classFile.getText()
	If (Position:C15("shared singleton Class constructor"; $classContent)=0)
		continue
	End if 
	
	var $className:=$classFile.name
	
	var $lines:=Split string:C1554($classContent; "\n")
	var $line; $httpMethod; $functionName; $pattern; $comment : Text
	
	var $index : Integer:=0
	For ($index; 0; $lines.length-1)
		$line:=$lines[$index]
		
		If ((Position:C15("IncomingMessage"; $line)=0) || (Position:C15("OutgoingMessage"; $line)=0) || (Position:C15("Function "; $line)=0))
			continue
		End if 
		
		$comment:=$lines[$index-1]
		var $pos:=Position:C15("// @"; $comment)
		If ($pos=0)
			continue
		End if 
		$comment:=Substring:C12($comment; $pos+4)
		$pos:=Position:C15("("; $comment)
		If ($pos=0)
			continue
		End if 
		$httpMethod:=Lowercase:C14(Substring:C12($comment; 1; $pos-1))
		$comment:=Substring:C12($comment; $pos+1)
		$pos:=Position:C15(")"; $comment)
		If ($pos=0)
			continue
		End if 
		$pattern:=Substring:C12($comment; 1; $pos-1)
		
		$functionName:=Substring:C12($line; Position:C15("Function "; $line)+Length:C16("Function "))
		$pos:=Position:C15("("; $functionName)
		If ($pos=0)
			continue
		End if 
		$functionName:=Substring:C12($functionName; 1; $pos-1)
		
		$handlers.push({class: $className; method: $functionName; pattern: $pattern; verbs: $httpMethod})
		
	End for 
	
End for each 

var $handlersFile:=Folder:C1567(fk database folder:K87:14; *).file("Project/Sources/HTTPHandlers.json")
$handlersFile.setText(JSON Stringify:C1217($handlers; *))