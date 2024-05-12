#include 'totvs.ch'
#INCLUDE "TOPCONN.CH"

/*/{Protheus.doc} TPDVP013
Ponto de entrada executado no in�cio do cancelamento (StwCncSale)

@type function
@version 1.0
@author thebr
@since 20/12/2020
@return bolean, prosseguir com cancelamento ou n�o
/*/
User function TPDVP013()

	Local aArea := GetArea()
	Local aAreaSL1 := SL1->(GetArea()) //Salva area SL1
	Local lRet := .T.

	Local lAchouSL1	:= .F. // Variavel de retorno se encontrou o SL1 ou nao
	Local nHoras := 0 // Quantidade de horas da hora atual
	Local dDtDigit := dDataBase	// Data da emissao da nota
	Local nNfceExc := SuperGetMV("MV_NFCEEXC",, 0) // Indica a quantidade de horas q a NFCe pode ser cancelada
	Local nSpedExc := SuperGetMV("MV_SPEDEXC",,72) // Indica a quantidade de horas q a NFe pode ser cancelada
	Local cHoraRMT := SuperGetMV("MV_HORARMT",,"1")	// 1 - Considera a hora do SmartCient | 2 - Considera a hora do Servidor | 3 - Fuso hor�rio da filial corrente
	Local cNumSale := PARAMIXB[1]
	//Local cNumNota := PARAMIXB[2]
	//Local cSerNota := PARAMIXB[3]
	Local lEndFis := SuperGetMv("MV_SPEDEND",, .F.)		// Se estiver como F refere-se ao endere�o de Cobran�a se estiver T ao endere�o de Entrega.
	Local cEstSM0 := IIf(!lEndFis, SM0->M0_ESTCOB, SM0->M0_ESTENT)
	Local cHoraUF := FwTimeUF(cEstSM0)[2]
	Local lHverao := .F.
	Local dHVeraoI := SuperGetMV("MV_HVERAOI",.F.,CTOD('  /  /    '))
	Local dHVeraoF := SuperGetMV("MV_HVERAOF",.F.,CTOD('  /  /    '))
	Local cPdv := AllTrim(LjGetStation("LG_PDV")) // PDV da estacao
	Local cTiposDoc := AllTrim( SuperGetMV('MV_ESPECIE')) // Tipos de documentos fiscais utilizados na emissao de notas fiscais //1=SPED;U=NFS;UNI=RPS;4=SPED;5=NFCE;
	Local aTiposDoc := StrTokArr2(cTiposDoc,';',.T.)
	Local nX := 0, nPosEsp := 0
	Local lOpenCash := STBOpenCash()
	Local cMsgErro := ""
	Local lVldDtAba := SuperGetMv("MV_VLDDTAB",,.F.) //habilita validacao data do abastecimento, dia anterior
	Local dMvDtVAba 
	Local dDtMID := stod("")

//solicita��o NUTRIZA: n�o cancelar se estiver em CONTING�NCIA
//chamado: POSTO-56 - Erro no Cancelamento de NFC-e
	Local oLOJGNFCE
	Local aMVMODNFCE := {}
	Local cMVMODNFCE := ""
	Local lBlqCont := SuperGetMV("TP_BLQCANC",,.F.) //Bloqueia cancelamento de NFC-e quando ambiente estiver em conting�ncia ou sem protocolo? (default .F.)

//solicita��o LARCO: permiss�o de acesso para rotina de cancelamento de cupom
//chamado: POSTO-734 - Validar a permiss�o de usu�rio para cancelamento de cupom
	Local lVldCanc := SuperGetMV("TP_VLCCANC",,.F.) //Valida a permiss�o de acesso para cancelamento de cupom (default .F.)
	Local cUsrAfc := ""

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combust�vel (Posto Inteligente).
	//Caso o Posto Inteligente n�o esteja habilitado n�o faz nada...
	If !lMvPosto
		Return .T.
	EndIf

	STFCleanMessage()
	STFCleanInterfaceMessage()

	For nX:=1 to Len(aTiposDoc) //1=NF;7=SPED;U=NFS;UNI=RPS;6=NFCE;
		aTiposDoc[nX] := StrTokArr2(aTiposDoc[nX],'=',.T.)
	Next nX

	DbSelectArea( "SL1" )
	SL1->( DbSetOrder(1) ) //L1_FILIAL+L1_NUM
	lAchouSL1 := SL1->( DbSeek( xFilial("SL1") + cNumSale ) )

	If lVldCanc .and. !IsInCallStack("U_TPDVP02A") .and. lAchouSL1 .and. !Empty(SL1->L1_DOC) .and. !Empty(SL1->L1_SERIE)
		//verifica se o usu�rio tem permiss�o para acesso a rotina
		U_TRETA37B("VLDCAN", "CANCELAMENTO DE CUPOM NO PDV (TP_VLCCANC)")
		cUsrAfc := U_VLACESS1("VLDCAN", RetCodUsr())
		If cUsrAfc == Nil .OR. Empty(cUsrAfc)
			STFMessage(ProcName(),"STOP", "Usu�rio n�o tem permiss�o para cancelar cupom fiscal." )
			STFShowMessage(ProcName())
			Return .F.
		EndIf
	EndIf

	//verifica se ha alguma compensa��o vinculada na venda
	if lAchouSL1 .and. !Empty(SL1->L1_DOC) .and. !Empty(SL1->L1_SERIE) .AND. UC0->(FieldPos("UC0_DOC")) > 0 .AND. UC0->(FieldPos("UC0_SERIE")) > 0
		if !VldCmpVenda()
			STFMessage(ProcName(),"STOP", "H� compensa��o vinculada a esta venda. Cancele primeiro a compensa��o." )
			STFShowMessage(ProcName())
			Return .F.
		endif
	endif

//verifica se esta dentro do prazo de cancelamento
	If lAchouSL1 .and. Len(aTiposDoc)>0
		
		nPosEsp := aScan(aTiposDoc,{|x| AllTrim(x[1])==AllTrim(SL1->L1_SERIE)})

		// Verifica se eh uma NF-e, pois neste caso deve respeitar o MV_SPEDEXC, que indica qual o prazo max para cancelamento
		If nPosEsp>0 .and. aTiposDoc[nPosEsp][2]="SPED"

			If cHoraRMT == "1" // Horario do SmartClient
				cHoraUF := SubStr(GetRmtTime(),1,8)
			ElseIf cHoraRMT == "3" // Fuso hor�rio do estado
				// Verifica se � hor�rio de ver�o (compatibilidade com os demais modulos)
				If !Empty(dHVeraoI) .And. !Empty(dHVeraoF) .And. dDataBase >= dHVeraoI .And. dDataBase <= dHVeraoF
					lHverao := .T.
				EndIf
				cHoraUF := FwTimeUF(SM0->M0_ESTENT,,lHVerao)[2]
			Else // 2- Default - Horario do Server
				cHoraUF := SubStr(Time(),1,8)
			EndIf

			dDtdigit := IIf(!Empty(SL1->L1_EMISNF), SL1->L1_EMISNF, SL1->L1_EMISSAO)
			nHoras   := SubtHoras( dDtdigit, SL1->L1_HORA, dDATABASE, SubStr(cHoraUF,1,2) + ":" + SubStr(cHoraUF,4,2) )

			If nHoras > nSpedExc
				cMsgErro := "O prazo para o cancelamento do NF-e � de" + " " + cValToChar(nSpedExc) + " horas (MV_SPEDEXC)."
				lRet := .F.	
			EndIf

		// Verifica se eh uma NFC-e, pois neste caso deve respeitar o MV_NFCEEXC, que indica qual o prazo max para cancelamento
		ElseIf nPosEsp>0 .and. aTiposDoc[nPosEsp][2]="NFCE"
			
			dDtdigit := IIf(!Empty(SL1->L1_EMISNF), SL1->L1_EMISNF, SL1->L1_EMISSAO)
			nHoras   := SubtHoras( dDtdigit, SL1->L1_HORA, dDataBase, SubStr(cHoraUF,1,2)+":"+SubStr(cHoraUF,4,2) )

			//Tratamento para manter o legado do parametro MV_NFCEEXC 
			If nNfceExc <= 0
				nNfceExc := nSpedExc
			EndIf

			If nHoras > nNfceExc
				cMsgErro := "O prazo para o cancelamento do NFC-e � de" + " " + Alltrim(STR(nNfceExc))+" horas (MV_NFCEEXC)."
				lRet := .F.
			EndIf

			If lRet .and. lBlqCont
				//valida se ambiente esta em conting�ncia
				oLOJGNFCE := LOJGNFCE():New()                                 // -- Constroi objeto LOJGNFCE
				aMVMODNFCE := oLOJGNFCE:LjGetMVTSS("MV_MODNFCE",,,,"1")       // -- Retorna o parametro MV_MODNFCE no TSS Array: {{Entidade,Conteudo},{Entidade,Conteudo},{Entidade,Conteudo},....}
				cMVMODNFCE := aMVMODNFCE[1][2] // -- Conteudo do parametro MV_MODNFCE no TSS: 1-Normal, 2-Contingencia 
				If cMVMODNFCE == "2"
					cMsgErro := "Conting�ncia Off-Line esta habilitada. N�o ser� permitido realizar o cancelamento da NFC-e (TP_BLQCANC)."
					lRet := .F.
				Else
					//valida se existe protocolo de autoriza��o
					If !Empty(SL1->L1_SERIE) .and. !Empty(SL1->L1_DOC) .and. !Empty(SL1->L1_KEYNFCE)
						aDados := {}
						lNFe := (Substr(SL1->L1_KEYNFCE,21,2) == "55")

						//-- Vamos Verificar se foi autorizado na SEFAZ
						//-- [01] = Versao
						//-- [02] = Ambiente
						//-- [03] = Cod Retorno Sefaz
						//-- [04] = Descricao Retorno Sefaz
						//-- [05] = Protocolo
						//-- [06] = Hash
						aDados  := U_STMVLSEF( .F./*n�o consulta no TSS Local*/, {{SL1->L1_KEYNFCE,"",lNFe}} )
						If Len(aDados) < 5 .or. Empty(aDados[05])
							cMsgErro := "Nota sem protocolo de autoriza��o. N�o ser� permitido realizar o cancelamento da NFC-e (TP_BLQCANC)."
							lRet := .F.
						EndIf
					EndIf
				EndIf
			EndIf

		EndIf

	EndIf

//verifica se a venda pertence ao mesmo PDV da esta��o logada
	If lRet .and. lAchouSL1 .and. AllTrim(SL1->L1_PDV) <> AllTrim(cPdv)
		cMsgErro := "A nota pertence a outro esta��o. N� PDV da nota: " + SL1->L1_PDV + ". N� PDV logado: "+cPdv+"."
		lRet := .F.
	EndIf

	RestArea(aAreaSL1)

//verifica caixa aberto
	If lRet .and. !lOpenCash
		cMsgErro := "Realize a abertura do caixa para executar esta op��o."
		lRet := .F.
	Endif

//atualizo nome do cliente na tela, DEIXAR POR ULTIMO
	if lRet
		U_SetTbcCli("")
		U_HideMsgNF()
		U_HidePnlForm()
		U_TPDVE04B(.F.) // Reseto op��o vinculo compensa��o na venda

		//volto parametor validacao abastecimento dia anterior
		if lVldDtAba .AND. lAchouSL1 
			dMvDtVAba := STOD(GetMv("MV_DTUVABA")) //ultima data validada
			if !empty(dMvDtVAba)
				dDtMID := dMvDtVAba
				//buscar maior data dos abastecimentos da venda atual
				SL2->(DbSetOrder(1))
				SL2->(DbSeek(xFilial("SL2")+SL1->L1_NUM))
				While SL2->(!Eof()) .AND. SL2->L2_FILIAL+SL2->L2_NUM == xFilial("SL2")+SL1->L1_NUM
					if !empty(SL2->L2_MIDCOD)
						if Posicione("MID",1,xFilial("MID")+SL2->L2_MIDCOD, "MID_DATACO") < dDtMID
							dDtMID := MID->MID_DATACO
						endif
					endif
					SL2->(DbSkip())
				enddo
				if dDtMID <> dMvDtVAba
					GetMv("MV_DTUVABA")
					PutMvPar("MV_DTUVABA", DTOS( dDtMID ) )
				endif
			endif
		endif
	else
		MsgAlert(cMsgErro,"STOP")
		STFMessage(ProcName(),"STOP",cMsgErro)
		STFShowMessage(ProcName())
	endif

	RestArea(aArea)

Return lRet

//--------------------------------------------------------------------------------------
// Verifica se h� compensacao vinculada na venda
//--------------------------------------------------------------------------------------
Static Function VldCmpVenda()

	Local nQtdUC0 := 0
	Local cQry := ""
	Local lRet := .T.

	//busco vendas dentro do intervalo de datas do caixa
	cQry := " SELECT COUNT(*) QTDUC0 "
	cQry += " FROM "+RetSqlName("UC0")+" UC0 "
	cQry += " WHERE UC0.D_E_L_E_T_= ' ' "
	cQry += " AND UC0_DOC = '"+SL1->L1_DOC+"' "
	cQry += " AND UC0_SERIE = '"+SL1->L1_SERIE+"' "
	cQry += " AND UC0_ESTORN <> 'X' " //nao estornada

	If Select("QRYUC0") > 0
		QRYUC0->(DbCloseArea())
	Endif

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYUC0" // Cria uma nova area com o resultado do query

	If QRYUC0->(!Eof())
		nQtdUC0 := QRYUC0->QTDUC0
	EndIf

	QRYUC0->(DbCloseArea())

	lRet := nQtdUC0 == 0

Return lRet
