#INCLUDE 'PROTHEUS.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETE004
Fun��o que apaga o Cart�o Identfid do vendedor da concentradora.

@author Wellington Gon�alves
@since 21/05/2014
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETE004()

Local cRetorno		:= ""
Local cCartao		:= ""
Local cMemori		:= ""
Local cRetApagado	:= ""
Local cRetRequerido	:= ""
Local cRetCartao	:= ""
Local lRet			:= .T.

// posiciono na tabela de concentradoras
MHX->(DbSetOrder(1)) //MHX_FILIAL+MHX_CODCON
if MHX->(DbSeek(xFilial("MHX") + U68->U68_CONCEN))

	if MHX->MHX_CODFAB == "03" // se a concentradora for Fusion
		Help( ,, 'HELP',, 'Esta funcionalidade n�o est� dispon�vel para concentradora Fusion!', 1, 0)
		lRet := .F.
	else
	
		if Empty(U68->U68_MEMORI)
			Help( ,, 'HELP',, 'Este cart�o n�o est� cadasrado na concentradora!', 1, 0)		
			lRet := .F.			
		else
		
			if MsgYesNo("Deseja apagar este n�mero de cart�o na " + AllTrim(MHX->MHX_DESC) + " ("+AllTrim(MHX->MHX_MODELO)+") ?")
				
				cCartao	:= PADL(AllTrim(U68->U68_NUM),16,"")
				cMemori	:= PADL(AllTrim(U68->U68_MEMORI),6,"")
				
				// envio o comando para integra��o com a concentradora
				cRetorno := U_TRETE001(MHX->MHX_CODCON,"5",{cCartao,cMemori})
				
				if Empty(cRetorno) .OR. cRetorno == "000000"
					Help( ,, 'HELP',, 'N�o foi poss�vel apagar o Cart�o Identfid na concentradora!', 1, 0)  
					lRet := .F.
				else
					
					cRetApagado		:= SubStr(cRetorno,3,6)
					cRetRequerido	:= SubStr(cRetorno,9,6)
					cRetCartao 		:= SubStr(cRetorno,15,16)
					
					// limpo a posi��o de mem�ria da concentradora no cart�o do vendedor
					if RecLock("U68",.F.)
						
						U68->U68_MEMORI := ""
						U68->(MsUnlock())
						
						Help( ,, 'HELP',, 'C�digo do cart�o apagado com sucesso!', 1, 0)
						
					endif
					
				endif
				
			else		
				lRet := .F.		
			endif
		
		endif
	
	endif
	
else
	Help( ,, 'HELP',, 'Concentradora informada no Cart�o Identfid inv�lida!', 1, 0)
endif

Return(lRet)
