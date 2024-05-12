#INCLUDE 'PROTHEUS.CH'
#INCLUDE "topconn.ch"
#INCLUDE "TbiConn.ch"

/*/{Protheus.doc} TRETE005
Função que limpa todos os registros Identfid da concentradora.

@author Wellington Gonçalves
@since 21/05/2014
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETE005()

Local lRet := .T.

if MHX->MHX_CODFAB == "03" // se a concentradora for Fusion
	Help( ,, 'HELP',, 'Esta funcionalidade não está disponível para concentradora Fusion!', 1, 0)
	lRet := .F.
else

	if MsgYesNo("Deseja limpar todos os registros identfid da concentradora " + AllTrim(MHX->MHX_DESC) + " ("+AllTrim(MHX->MHX_MODELO)+")?")
		
		// envio o comando para integração com a concentradora
		if U_TRETE001(MHX->MHX_CODCON,"6")   
			
			// limpo o campo Memoria de todos os cartoes desta concentradora
			U68->(DbSetOrder(4)) // U68_FILIAL+U68_CONCEN
			U68->(DbGoTop())
			if U68->(DbSeek(xFilial("U68") + MHX->MHX_CODCON))
			
				While U68->(!Eof()) .AND. U68->U68_FILIAL == xFilial("U68") .AND. U68->U68_CONCEN == MHX->MHX_CODCON
				    
				    if Reclock("U68",.F.) 
				       
				    	U68->U68_MEMORI := ""
				    	U68->(MsUnlock())
				    
				    endif
					
					U68->(DbSkip())
				
				EndDo
			
			endif  

			Help( ,, 'HELP',, 'Registros excluídos com sucesso!', 1, 0)
	
		else
			Help( ,, 'HELP',, 'Não foi possível excluir os registros da concentradora ' + AllTrim(MHX->MHX_DESC) + ' ('+AllTrim(MHX->MHX_MODELO)+')!', 1, 0)
			lRet := .F.	
		endif
		
	else	
		lRet := .F.	
	endif

endif

Return(lRet)
