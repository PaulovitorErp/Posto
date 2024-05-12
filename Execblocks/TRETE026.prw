#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'RWMAKE.CH'
#INCLUDE 'TBICONN.CH' 

/*/{Protheus.doc} TRETE026
Job faz a geração dos títulos de cheque troco, quando o modo OFF-LINE estiver ATIVO

@author Totvs GO
@since 02/05/2019
@version 1.0
@return ${return}, ${return_description}

@param _cXEmp, character, empresa
@param _cXFil, character, filial

@type function
/*/
User Function TRETE026()
    
	Local cQry := ""
  	Local lSitua := .T.

	//Conout(">> INICIO TRETE026 - GERA FINANCEIRO CHEQUE TROCO")
	
	DbSelectArea("UF2")

	cQry := " SELECT * "
	cQry += " FROM " + RetSqlName("UF2") + " UF2"
	cQry += " WHERE UF2_FILIAL = '" + xFilial("UF2") + "'"
	cQry += 	" AND UF2.D_E_L_E_T_ = ' '"
	//cQry += 	" AND UF2_SERIE <> 'CMP'"
	cQry += 	" AND ((UF2_XGERAF = 'P') OR UF2_XGERAF IN ('E','X'))"
	
	If Select("T_UF2")>0
		T_UF2->(DbCloseArea())
	EndIf
	
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "T_UF2" // Cria uma nova area com o resultado do query
	
	T_UF2->(DbGoTop())
	While T_UF2->(!Eof())
	
		UF2->(DbGoTo(T_UF2->R_E_C_N_O_))
		lSitua := .T.
		
		If UF2->(!Eof())
		
			// preenche as variaveis para geração do financeiro
			nRecUF2	:= UF2->(Recno())
			
			//Conout(" >> TRETE026 "+UF2->UF2_XGERAF+ "- CHAVE CHEQUE: " + UF2->(UF2_FILIAL+UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_NUM) + " VALOR: " + STR(UF2->UF2_VALOR) + " DOC/SERIE: " + UF2->UF2_DOC +"/"+UF2->UF2_SERIE )
			
			// se entrar aqui é para gerar o estorno financeiro
			If UF2->UF2_XGERAF == 'E'
				U_TRETE29C(nRecUF2,.T.) //estorno com replica
				
			ElseIf UF2->UF2_XGERAF == 'X'
				U_TRETE29C(nRecUF2,.F.) //estorno sem replica
				
			// se entrar aqui é para gerar financeiro
			ElseIf UF2->UF2_XGERAF == 'P'
				U_TRETE029(nRecUF2)
				
			EndIf
		
		EndIf
		
		T_UF2->(DbSkip())
	EndDo
	
	If Select("T_UF2")>0
		T_UF2->(DbCloseArea())
	EndIf
			
	//Conout(">> FIM TRETE026 - GERA FINANCEIRO CHEQUE TROCO")
    
Return 
