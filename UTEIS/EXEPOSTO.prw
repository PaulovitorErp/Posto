#INCLUDE 'protheus.ch'
#INCLUDE 'parmtype.ch'

/*/{Protheus.doc} EXEPOSTO
Executa rotinas de forma dinamica, passando o nome da função e parametros.

@author pablo
@since 23/05/2019
@version 1.0
@return ${return}, ${return_description}
@param cFuncao, characters, descricao
@param aParam, array, descricao
@type function
/*/
User Function EXEPOSTO(cFuncao,aParam)
Local xRet := Nil // Retorno da funcao
Local nI := 0 // Contador
Local cParametros := "" // Parametros da funcao
	
	If FindFunction(cFuncao) //ExistBlock(cFuncao)
		//xRet := ExecBlock(cFuncao,.F.,.F.,aParam)
		For nI := 1 To Len(aParam)
			cParametros += IIF(nI <> 1, ", ", "") + "aParam[" + AllTrim(Str(nI)) + "]"
		Next nI
		xRet := Eval(&("{|| " + cFuncao + "(" + cParametros + ")}"))  
	EndIf
	
Return xRet