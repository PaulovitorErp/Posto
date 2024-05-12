#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} TRETM029
Ponto de Entrada do MVC de Cadastro de Tipo de Preço Base.
@author pablo
@since 17/04/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETM029()

	Local aParam 		:= PARAMIXB
	Local xRet       	:= .T.
	Local oObj			:= aParam[1]
	Local cIdPonto		:= aParam[2]
	Local cIdModel		:= IIf( oObj<> NIL, oObj:GetId(), aParam[3] )
	Local cClasse		:= IIf( oObj<> NIL, oObj:ClassName(), '' )
	Local oModelU0A		:= oObj:GetModel( 'U0AMASTER' )
	
	Static oSay

	If cIdPonto == 'MODELCOMMITNTTS'

		If oObj:GetOperation() == 3 // inclusão

			//U_UReplica("U0A",1,xFilial("U0A") + oModelU0A:GetValue('U0A_FORPAG') + oModelU0A:GetValue('U0A_CONDPG') + oModelU0A:GetValue('U0A_ADMFIN'),"I")
			//If MsgNoYes('Deseja atualizar o valor de Desconto/Acrescimo do preço base das negociações cadastradas?','Atenção')
			//	FWMsgRun(, {|oSay| lOk := AtualizaU25( oSay, oModelU0A:GetValue('U0A_FORPAG'), oModelU0A:GetValue('U0A_CONDPG'), oModelU0A:GetValue('U0A_ADMFIN') ) }, "Aguarde... Ajustando preço negociado...", "Processando ajuste de preço negociado...")
			//EndIf

		ElseIf oObj:GetOperation() == 4 // alteração

			//U_UReplica("U0A",1,xFilial("U0A") + oModelU0A:GetValue('U0A_FORPAG') + oModelU0A:GetValue('U0A_CONDPG') + oModelU0A:GetValue('U0A_ADMFIN'),"A")

		ElseIf oObj:GetOperation() == 5 // exclusão

			//U_UReplica("U0A",1,xFilial("U0A") + oModelU0A:GetValue('U0A_FORPAG') + oModelU0A:GetValue('U0A_CONDPG') + oModelU0A:GetValue('U0A_ADMFIN'),"E")

		EndIf

	EndIf
	
Return xRet

//
// Ajusta os DESCONTO/ACRESCIMO (U25_DESPBA) do tipo de preço base cadastrado
//
Static Function AtualizaU25( oSay , cForma, cCond, cAdm )

Local cSQL := "", cSqlUpd := ""
Local nCountSPDX := 0
Local lTipoPreco := GetMv("MV_LJCNVDA")
Local cTabPrc	 := GetMv("MV_TABPAD")

	cSQL := "select count(*) as QTD" + CRLF
	cSQL += " from " + RetSqlName("U25") + " U25" + CRLF
	cSQL += " where U25.D_E_L_E_T_ <> '*'" + CRLF
	cSQL += " and U25.U25_FILIAL = '" + xFilial("U25") + "'" + CRLF
	cSQL += " and (U25.U25_DTFIM = '' or U25.U25_DTFIM >= '"+DtoS(Date())+"')" + CRLF //-- preços ativos
	cSQL += " and U25.U25_FORPAG = '" + cForma + "'" + CRLF
	if !Empty(cCond)
		cSQL += " and U25.U25_CONDPG = '" + cCond + "'" + CRLF
	endif
	if !Empty(cAdm)
		cSQL += " and U25.U25_ADMFIN = '" + cAdm + "'" + CRLF
	endif
	//cSQL += " and U25.U25_DESPBA = 0 " + CRLF //-- temporariamente (PREÇO DE DESCONTO MAIOR DO R$ 1,00)
	cSQL += " group by U25.U25_FILIAL"

	If Select("SPDX") > 0
		SPDX->( DbCloseArea() )
	EndIf	

	cSQL := ChangeQuery(cSQL)
	TcQuery cSQL New ALIAS "SPDX"

	nCountSPDX := 0

	If !SPDX->( Eof() )
		//SPDX->(dbEval({|| nCountSPDX++}))
		nCountSPDX := SPDX->QTD
	EndIf

	If oSay <> NIL
		oSay:cCaption := 'Quantidade registros Negociação de Preço a serem atualizados: ' + cValToChar(nCountSPDX)
		ProcessMessages()
	EndIf

	//Conout("")
	//Conout("")
	//Conout('Quantidade registros Negociação de Preço a serem atualizados: ' + cValToChar(nCountSPDX))
	//Conout("")
	//sleep(2000)
	
	cSQL := "select U25.R_E_C_N_O_ as U25RECNO" + CRLF
	cSQL += " from " + RetSqlName("U25") + " U25" + CRLF
	cSQL += " where U25.D_E_L_E_T_ = ' '" + CRLF
	cSQL += " and U25.U25_FILIAL = '" + xFilial("U25") + "'" + CRLF
	cSQL += " and (U25.U25_DTFIM = '' or U25.U25_DTFIM >= '"+DtoS(Date())+"')" + CRLF //-- preços ativos
	cSQL += " and U25.U25_FORPAG = '" + cForma + "'" + CRLF
	If !Empty(cCond)
		cSQL += " and U25.U25_CONDPG = '" + cCond + "'" + CRLF
	EndIf
	If !Empty(cAdm)
		cSQL += " and U25.U25_ADMFIN = '" + cAdm + "'" + CRLF
	EndIf
	//cSQL += " and U25.U25_DESPBA = 0 " + CRLF //-- temporariamente (PREÇO DE DESCONTO MAIOR DO R$ 1,00)

	If Select("SPDX") > 0
		SPDX->( DbCloseArea() )
	EndIf
	
	cSQL := ChangeQuery(cSQL)
	TcQuery cSQL New ALIAS "SPDX"
	
	nCount := 1
	
	While SPDX->(!Eof()) //;
		//.and. nCount <= 2  //-- temporario pra processar somente 1 registro
		
		If oSay <> NIL
			oSay:cCaption := 'Processando registro: ' + cValToChar(nCount) + '/' +cValToChar(nCountSPDX)
			ProcessMessages()
		EndIf
		//Conout('Processando registro: ' + cValToChar(nCount) + '/' +cValToChar(nCountSPDX))
		
		U25->(DbGoTo(SPDX->U25RECNO))
		
		nPrcBas := U_URetPrBa(U25->U25_PRODUT, U25->U25_FORPAG, U25->U25_CONDPG, U25->U25_ADMFIN, 0, U25->U25_DTINIC, U25->U25_HRINIC)
		
		If U25->U25_DESPBA <> ( nPrcBas - U25->U25_PRCVEN )
			RecLock("U25",.F.)
				U25->U25_DESPBA := ( nPrcBas - U25->U25_PRCVEN )
				U25->U25_MSEXP  := ""
				U25->U25_HREXP  := ""
			U25->(MsUnlock())
		EndIf
		U_UREPLICA("U25", 1, U25->U25_FILIAL+U25->U25_REPLIC, "A")
		
		nCount++
		
		SPDX->(DbSkip())
	EndDo

	If Select("SPDX") > 0
		SPDX->( DbCloseArea() )
	EndIf

	//cSqlUpd := "update " + RetSqlName("U25") + " U25"
	//cSqlUpd += " set "
	//cSqlUpd += 		" U25.U25_DESPBA = - " 
	//cSqlUpd += " where r_e_c_n_o_ = '" + AllTrim( Str(SPDX->RECNO) ) + "' "
	//TCSQLEXEC(cSqlUpd)

Return
