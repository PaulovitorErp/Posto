#INCLUDE 'PROTHEUS.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETE004
Função que apaga o Cartão Identfid do vendedor da concentradora.

@author Wellington Gonçalves
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
		Help( ,, 'HELP',, 'Esta funcionalidade não está disponível para concentradora Fusion!', 1, 0)
		lRet := .F.
	else
	
		if Empty(U68->U68_MEMORI)
			Help( ,, 'HELP',, 'Este cartão não está cadasrado na concentradora!', 1, 0)		
			lRet := .F.			
		else
		
			if MsgYesNo("Deseja apagar este número de cartão na " + AllTrim(MHX->MHX_DESC) + " ("+AllTrim(MHX->MHX_MODELO)+") ?")
				
				cCartao	:= PADL(AllTrim(U68->U68_NUM),16,"")
				cMemori	:= PADL(AllTrim(U68->U68_MEMORI),6,"")
				
				// envio o comando para integração com a concentradora
				cRetorno := U_TRETE001(MHX->MHX_CODCON,"5",{cCartao,cMemori})
				
				if Empty(cRetorno) .OR. cRetorno == "000000"
					Help( ,, 'HELP',, 'Não foi possível apagar o Cartão Identfid na concentradora!', 1, 0)  
					lRet := .F.
				else
					
					cRetApagado		:= SubStr(cRetorno,3,6)
					cRetRequerido	:= SubStr(cRetorno,9,6)
					cRetCartao 		:= SubStr(cRetorno,15,16)
					
					// limpo a posição de memória da concentradora no cartão do vendedor
					if RecLock("U68",.F.)
						
						U68->U68_MEMORI := ""
						U68->(MsUnlock())
						
						Help( ,, 'HELP',, 'Código do cartão apagado com sucesso!', 1, 0)
						
					endif
					
				endif
				
			else		
				lRet := .F.		
			endif
		
		endif
	
	endif
	
else
	Help( ,, 'HELP',, 'Concentradora informada no Cartão Identfid inválida!', 1, 0)
endif

Return(lRet)
