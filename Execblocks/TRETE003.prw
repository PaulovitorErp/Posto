#INCLUDE 'PROTHEUS.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETE003
Fun��o que cadastra o cart�o identfid do vendedor na concentradora.

@author Wellington Gon�alves
@since 27/09/2017
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETE003()

Local cRetorno		:= ""
Local cTiniA		:= ""
Local cTfimA		:= ""
Local cTiniB		:= ""
Local cTfimB		:= ""
Local cCartao		:= ""
Local cRetPosicao	:= ""
Local nRetQuant		:= 0
Local cRetCartao	:= ""
Local lRet			:= .T.
Local lNivCBC		:= SuperGETMV('MV_XNIVCBC',,.F.)
Local cControle		:= ""

// posiciono na tabela de concentradoras
MHX->(DbSetOrder(1))
if MHX->(DbSeek(xFilial("MHX") + U68->U68_CONCEN))

	if MHX->MHX_CODFAB == "03" // se a concentradora for Fusion
		Help( ,, 'HELP',, 'Esta funcionalidade n�o est� dispon�vel para concentradora Fusion!', 1, 0) 
		lRet := .F.
	else
	
		if MsgYesNo("Deseja enviar este n�mero de cart�o para a " + AllTrim(MHX->MHX_DESC) + " ("+AllTrim(MHX->MHX_MODELO)+")"+ "?")
			
			if !Empty(U68->U68_MEMORI)
				
				Help( ,, 'HELP',, 'Este cart�o j� est� cadastrado na concentradora!', 1, 0)
				
				// fun��o que excluir o codigo identfid da concentradora
				if !U_TRETE004()
					Return(.F.)
				endif
				
			endif
			
			cCartao	:= PADL(AllTrim(U68->U68_NUM),16,"")
			cTiniA 	:= PADL(AllTrim(StrTran(U68->U68_TINIA,":","")),4,"")
			cTfimA	:= PADL(AllTrim(StrTran(U68->U68_TFIMA,":","")),4,"")
			cTiniB	:= PADL(AllTrim(StrTran(U68->U68_TINIB,":","")),4,"")
			cTfimB	:= PADL(AllTrim(StrTran(U68->U68_TFIMB,":","")),4,"")
			
			// envio o comando para integra��o com a concentradora
			If lNivCBC .and. U68->( FieldPos("U68_TIPPRC") ) > 0 .and. !Empty(U68->U68_TIPPRC)
				If U68->U68_TIPPRC = "0"
					cControle := "27"//Dinheiro
				ElseIf U68->U68_TIPPRC = "1"
					cControle := "28"//D�bito
				ElseIf U68->U68_TIPPRC = "2"
					cControle := "29"//Credito
				Else
					cControle := "27" //(default -> Dinheiro)
				EndIf
				cRetorno := U_TRETE001(MHX->MHX_CODCON,"4",{cCartao,cTiniA,cTfimA,cTiniB,cTfimB,cControle})
			Else
				cRetorno := U_TRETE001(MHX->MHX_CODCON,"4",{cCartao,cTiniA,cTfimA,cTiniB,cTfimB})
			EndIf
			
			if Empty(cRetorno)
				Help( ,, 'HELP',, 'N�o foi poss�vel realizar a grava��o do cart�o Identfid!', 1, 0) 
				lRet := .F.
			else
				
				cRetPosicao	:= SubStr(cRetorno,3,6)
				nRetQuant	:= SubStr(cRetorno,9,6)
				cRetCartao	:= SubStr(cRetorno,15,16)
				
				// gravo a posi��o de mem�ria da concentradora no cart�o do vendedor
				if RecLock("U68",.F.)
					
					U68->U68_MEMORI := cRetPosicao
					U68->(MsUnlock())
					
					Help( ,, 'HELP',, 'C�digo do cart�o cadastrado com sucesso!', 1, 0)
					
				endif
				
			endif
			
		else		
			lRet := .F.		
		endif
	
	endif
	
else	
	Help( ,, 'HELP',, 'Concentradora informada no Cart�o Identfid inv�lida!', 1, 0)	
endif

Return(lRet)
