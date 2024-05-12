#INCLUDE "TOTVS.ch"
#INCLUDE "FWEVENTVIEWCONSTS.CH"
#INCLUDE "FWADAPTEREAI.CH"
#INCLUDE "stpos.ch"
#INCLUDE "POSCSS.CH"

Static oPnlCompTrc := Nil
Static oValorDi, oValorCh, oValorVl
Static nValorDi := 0
Static nValorCh := 0
Static nValorVl := 0
Static nQtdCht := 0
Static lActiveCHT := .F.
Static lActiveVLH := .F.

Static lSTConfSale := .F.
Static nMaxTroco   := 0
Static nTrocTot		:= 0

Static dDtVAba := STOD("")

/*/{Protheus.doc} TPDVP017
Função utilizada pelo Ponto de Entrada STConfSale
Validação das formas de pagamentos utilizadas na finalização da venda/recebimento de título no TOTVS PDV.

@author pablo
@since 14/05/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TPDVP017()

	Local lRet := .T. //Retorno logico
	Local lVaDtCx := SuperGetMv("MV_XVADTCX",,.T.) //Valida a data base referente a data do SO e abertura de caixa (default .T.)
	//Local aFormas    := PARAMIXB[1] // formas de pagamento (aCols do Grid)
	//Local aHeadPg    := PARAMIXB[2] // header das formas de pagamento (aHeader do Grid)
	Local lReceb     := PARAMIXB[3] // variável que indica se é recebimento de título
	//Local oWFReceipt := PARAMIXB[4] // o objeto da classe do recebimento de titulo - STIRetObjTit()
	//Local aPayment   := PARAMIXB[5] // pagamentos informados no sistema com todos os campos da SL4

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return lRet
	EndIf

	If lReceb //quando recebimento de título, não faz nada
		Return lRet
	EndIf

	If lVaDtCx .and. !(lRet := U_uValDtCx())
		Return lRet
	EndIf

	If !lSTConfSale .and. lRet
		lRet := ValidaCred() //valida limite de crédito: NP/CH/CF
	EndIf

	If lRet
		lRet := CompTroco() //composição do troco
	EndIf

	If lRet
		lRet := VldDtAbast() //valida data abastecimeno dia anterior
	EndIf

	If lRet
		LocEstoque() //ajusta local de estoque
	EndIf

	If lRet
		AjustaSL1() //ajuste dos dados da SL1
	EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} AjustaSL1
Ajusta dados da SL1

@author  Pablo Nunes
@since   26/06/2020
@version Protheus 12
/*/
//-------------------------------------------------------------------
Static Function AjustaSL1()

	Local cCodUsuario := RetCodUsr()
	Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.) //Habilita controle de caixa por Vendedor, com exigência de senha.
	Local oCliModel := STDGCliModel() 				// Model do Cliente
	Local cCliente := oCliModel:GetValue("SA1MASTER","A1_COD")
	Local cLojaCli := oCliModel:GetValue("SA1MASTER","A1_LOJA")
	Local lCliPad := (Alltrim(cCliente) == Alltrim(SuperGetMV("MV_CLIPAD"))) .and. (Alltrim(cLojaCli) == Alltrim(SuperGetMV("MV_LOJAPAD")))

	//Enquanto se tem o flag L1_FORCADA preenchido, aborta a subida da venda (esse campo padrão não usa no TotvsPDV)
	//Gravo o flag para só subir a venda após a execução do PE STFinishSale (TPDVP005).
	//Regra depende do ponto de entrada STDUPSL1.
	If SL1->(FieldPos("L1_FORCADA")) > 0
		STDSPBasket("SL1", "L1_FORCADA", "S")
	EndIf

	//-------------------------------------------------------------//
	// Ajuste do tipo de frete na SL1: LQ_TPFRET = S (Sem frete)
	//-------------------------------------------------------------//
	// venda presencial
	If STDGPBasket("SL1", "L1_TPFRET") <> "S"
		STDSPBasket("SL1", "L1_TPFRET", "S")
	EndIf

	//Ajuste dos caracteres especiais para NFC-e do cliente, para evitar dar erros de rejeiçao e qrcode.
	if !lCliPad .and. ExistFunc("LjRmvChEs")
		SA1->(DbSetOrder(1))
		if SA1->(DbSeek(xFilial("SA1")+cCliente+cLojaCli))
			//verifica tipo de nota
			//if U_TPDVP007(SA1->A1_COD, SA1->A1_LOJA, .T.) == 1 //"NFC-e"
				RecLock("SA1", .F.)
					SA1->A1_NOME := LjRmvChEs(SA1->A1_NOME)
					SA1->A1_END	:= LjRmvChEs(SA1->A1_END)
					SA1->A1_COMPLEM := LjRmvChEs(SA1->A1_COMPLEM)
					SA1->A1_BAIRRO := LjRmvChEs(SA1->A1_BAIRRO)
					SA1->A1_EMAIL := LjRmvChEs(SA1->A1_EMAIL)
				SA1->(MsUnlock())
			//endif
		endif
	endif

	//-------------------------------------------------------------//
	// Ajuste do vendedor da SL1: vendedor do operador logado
	//-------------------------------------------------------------//
	// verifico se o usuário caixa está vinculado a um vendedor
	If !lMvPswVend
		SA3->(DbSetOrder(7)) // A3_FILIAL + A3_CODUSR
		If SA3->(DbSeek(xFilial("SA3")+cCodUsuario))
			If  STDGPBasket("SL1", "L1_VEND") <> SA3->A3_COD
				STDSPBasket("SL1", "L1_VEND", SA3->A3_COD)
				STDSPBasket("SL1", "L1_COMIS", STDGComission( SA3->A3_COD ))
			EndIf
		EndIf
	Else //seta vendedor logado
		U_TpAtuVend()
	EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} LocEstoque
Ajusta local de estoque nos itens da cesta

@author  Pablo Nunes
@since   26/06/2020
@version Protheus 12
/*/
//-------------------------------------------------------------------
Static Function LocEstoque()

	Local oModelCesta := STDGPBModel()
	Local oModelSL2
	Local nI := 0
	Local cTanque := ""
	Local cLocExp := ""
	Local nPos := 0
	Local nPrcTab := 0
	Local nItemTotal

	//-------------------------------------------------------------
	// Ajuste do local de estoque
	//-------------------------------------------------------------
	oModelSL2 := oModelCesta:GetModel("SL2DETAIL")
	nPos := oModelSL2:GetLine() //guardo a linha posicionada
	For nI := 1 To oModelSL2:Length()
		oModelSL2:GoLine(nI)
		If !oModelSL2:IsDeleted(nI) //não esta deletado
			If Empty(oModelSL2:GetValue("L2_MIDCOD")) //ajuste para produtos que não são abastecimentos
				cLocExp := RetLocal(oModelSL2:GetValue("L2_PRODUTO")) //SLG (armazém do PDV) -> U59 (estoque de exposição) -> SB1 (armazém padrão)
				If !Empty(cLocExp) .and. AllTrim(oModelSL2:GetValue("L2_LOCAL")) <> AllTrim(cLocExp)
					oModelSL2:LoadValue("L2_LOCAL", cLocExp, nI)
					LjGrvLog( "L2_NUM: "+STDGPBasket("SL1","L1_NUM"), "TPDVP017 - L2_ITEM: " + oModelSL2:GetValue("L2_ITEM") + " | L2_PRODUTO: " + oModelSL2:GetValue("L2_PRODUTO") + " | L2_LOCAL: " + cLocExp + "" )
				EndIf
			ElseIf !Empty(oModelSL2:GetValue("L2_MIDCOD")) .and. Empty(oModelSL2:GetValue("L2_LOCAL")) //'força' o ajuste do armazem para abastecimentos
				cTanque := Posicione("MID", 1, xFilial("MID")+oModelSL2:GetValue("L2_MIDCOD"), "MID_CODTAN") //MID_FILIAL+MID_CODABA
				cLocExp := Posicione("MHZ", 1, xFilial("MHZ")+cTanque, "MHZ_LOCAL")
				If !Empty(cLocExp) .and. AllTrim(oModelSL2:GetValue("L2_LOCAL")) <> AllTrim(cLocExp)
					oModelSL2:LoadValue("L2_LOCAL", cLocExp, nI)
					LjGrvLog( "L2_NUM: "+STDGPBasket("SL1","L1_NUM"), "TPDVP017 - L2_ITEM: " + oModelSL2:GetValue("L2_ITEM") + " | L2_PRODUTO: " + oModelSL2:GetValue("L2_PRODUTO") + " | L2_LOCAL (tanque): " + cLocExp + "" )
				EndIf
			EndIf

			//TRATAMENTO PARA GRAVAR VALOR DO DESCONTO: chamado POSTO-291
			if SL2->(FieldPos("L2_DESCORC")) > 0
				nPrcTab := U_URetPrec(oModelSL2:GetValue("L2_PRODUTO")) //preço padrao
				nItemTotal := STBArred( nPrcTab * oModelSL2:GetValue("L2_QUANT"), , "L2_VLRITEM" )
				oModelSL2:LoadValue("L2_DESCORC", nItemTotal - oModelSL2:GetValue("L2_VLRITEM"), nI)
				oModelSL2:LoadValue("L2_CUSTO1", nPrcTab, nI) //guardo o preço tabela tbm por precaução
			endif

		EndIf
	Next nI
	oModelSL2:GoLine(nPos) //restaura a linha posicionada no model

Return .T.

//-------------------------------------------------------------------
/*/{Protheus.doc} RetLocal
Retorna o local estoque para determinado produto

@author  thebr
@since   30/11/2018
@version Protheus 12
@return Nil
@param cProd, characters, código do produto
@type function
/*/
//-------------------------------------------------------------------
Static Function RetLocal(cProd)

	Local aArea		:= GetArea()
	Local cLocal 	:= Space(TamSX3("L2_LOCAL")[1])
	Local cPriorid  := SuperGetMv("TP_LOCPRI",,"0") //Define prioridade a ser considerada na busca do local de estoque: 0=Estação/Exposição/Produto ou 1=0=Exposição/Estação/Produto

	//Verifica se possui Estoque de Exposição (no proceso da Marajó só pode haver 01 (um))
	If ChkFile("U59")
		DbSelectArea("U59")
		U59->(DbSetOrder(2)) //U59_FILIAL+U59_PRODUT
	EndIf

	//-------------------------------------------------------------
	// Pablo Nunes 	Data: 12/12/2017
	// Ajuste: com a finalidade de atender clientes que possuem mais de um estoque de exposição para o mesmo produto.
	// Neste caso, deverá ser criado o campo "LG_XLOCAL" no cadastro de estação e alimenta-lo com o estoque de exposição do PDV.
	//-------------------------------------------------------------
	if cPriorid == "1"

		If ChkFile("U59") .and. U59->(DbSeek(xFilial("U59")+cProd))
			cLocal := U59->U59_LOCAL
		ElseIf SLG->(FieldPos("LG_XLOCAL"))>0 .and. !Empty(SLG->LG_XLOCAL)
			cLocal := SLG->LG_XLOCAL
		Else
			//Senão, utilização almoxarifado padrão
			DbSelectArea("SB1")
			SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD

			If SB1->(DbSeek(xFilial("SB1")+cProd))
				cLocal := SB1->B1_LOCPAD
			Endif
		Endif
		
	else

		If SLG->(FieldPos("LG_XLOCAL"))>0 .and. !Empty(SLG->LG_XLOCAL)
			cLocal := SLG->LG_XLOCAL
		ElseIf ChkFile("U59") .and. U59->(DbSeek(xFilial("U59")+cProd))
			cLocal := U59->U59_LOCAL
		Else
			//Senão, utilização almoxarifado padrão
			DbSelectArea("SB1")
			SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD

			If SB1->(DbSeek(xFilial("SB1")+cProd))
				cLocal := SB1->B1_LOCPAD
			Endif
		Endif

	endif

	RestArea(aArea)

Return cLocal

//--------------------------------------------------------------------
// Validação de limite e bloqueio de crédito
//--------------------------------------------------------------------
Static Function ValidaCred()

	Local lActiveVCred := SuperGetMV("TP_ACTVCR",,.F.)
	Local lRet := .T.
	Local nPosMdl
	Local oMdl, oMdlPaym
	Local nX, cMsgErr
	Local oCliModel := STDGCliModel() 				// Model do Cliente
	Local cCliente := oCliModel:GetValue("SA1MASTER","A1_COD")
	Local cLojaCli := oCliModel:GetValue("SA1MASTER","A1_LOJA")
	Local lRetOn := IIF(GetPvProfString(CSECAO, CCHAVE, '0', GetAdv97()) == '0', .F., .T.)
	Local aLimites := {}, aParam := {}
	Local lAlcada	:= SuperGetMv("ES_ALCADA",.F.,.F.)
	Local lAlcLimit	:= SuperGetMv( "ES_ALCLIM",.F.,.F.)
	Local lLibLim := .F.
	Local cUsrLibVBL := ""
	Local cUsrLibVSL := ""
	Local cUsrLibLim := ""
	Local cMsgLibAlc := ""
	Local cGetCdUsr	 := RetCodUsr()
	Local lTP_ACTLCS := SuperGetMv("TP_ACTLCS",,.F.) //habilita limite de credito por segmento
	Local cSegmento := SuperGetMv("TP_MYSEGLC",," ") //define o segmento da filial do PDV (filial)
	Local lTP_ACTLGR := SuperGetMv("TP_ACTLGR",,.T.) //habilita limite de credito por grupo de clientes
	Local cLCOffline := SuperGetMV("TP_LCOFFLI",,"0") //define se vai usar limite offline e como vai usar: 0=Somente online; 1=Prioriza Online; 2=Apenas Offline

	/*Parametro Define a prioridade da validação de limite quando há grupo de clientes: 
	0=Limite Ambos: irá fazer a validação tanto do limite do cliente quanto do limite do grupo. Caso um 
		dos dois não tiver saldo para a operação, será barrada a venda (podendo liberar por supervisor). 
	1=Limite Grupo: irá ignorar a validação do limite do cliente, e fazer a validação apenas considerando o 
		limite do grupo*/
	Local cPriGrupo := SuperGetMv("TP_LCPRIOR",,"0") 

	Local aListCli := {} /*/{[01]"CGC",
	[02]"CLIENTE",
	[03]"LOJA",
	[04]"GRUPO",
	[05]"FORMA",
	[06]"VALOR",
	[07]"LIM CRED CLI",
	[08]"LIM USAD CLI",
	[09]"SLD LIM CLI",
	[10]"LIM CRED GRP",
	[11]"LIM USAD GRP",
	[12]"SLD LIM GRP",
	[13]"BLQ CLI",
							 [14]"BLQ GRP"} /*/

	if !lActiveVCred
		STFMessage(ProcName(),"STOP","Validação de limite de crédito desativado (TP_ACTVCR).")
		STFShowMessage(ProcName())
		Return lRet
	endif

	oMdl := STISetMdlPay() //Get no objeto oMdlPaym: Resumo do Pagamento
	If ValType(oMdl) == "O"
		oMdlPaym := oMdl:GetModel('APAYMENTS') //Get no model parcelas
		//carregar o total ja recebido
		If ValType(oMdlPaym) == "O"

			nPosMdl := oMdlPaym:GetLine() //guardo a linha posicionada

			For nX := 1 to oMdlPaym:Length()

				oMdlPaym:GoLine(nX) //vou para a ultima linha
				cForma := Alltrim(oMdlPaym:GetValue('L4_FORMA'))
				If cForma $ "CF/NP/CH" //"Carta Frete" ou "Nota a Prazo" ou "Cheque"

					//TODO: Criar campo virtual na SL4, Codigo+Loja, para posicionar no cliente correto
					If cForma <> "NP"
						cCgc := oMdlPaym:GetValue('L4_CGC') //-- CGC do emitente
						SA1->(DbSetOrder(3)) //A1_FILIAL+A1_CGC
						SA1->(DbSeek(xFilial("SA1")+cCgc))
					Else
						cCgc := Posicione("SA1",1,xFilial("SA1")+cCliente+cLojaCli,"A1_CGC") //-- CGC do cliente
					EndIf

					ACY->(DbSetOrder(1)) // ACY_FILIAL + ACY_GRPVEN
					ACY->(DbSeek(xFilial("ACY")+SA1->A1_GRPVEN))

					nPos := aScan( aListCli, {|x| AllTrim(x[01]) == AllTrim(cCgc)})
					If nPos <= 0
						aadd(aListCli,{ cCgc,;
							SA1->A1_COD,;
							SA1->A1_LOJA,;
							iif(lTP_ACTLGR,SA1->A1_GRPVEN,""),;
							cForma,;
							oMdlPaym:GetValue('L4_VALOR'),;
							SA1->A1_XLC,;
							0,;
							0,;
							Iif(ACY->(!Eof()),ACY->ACY_XLC,0),;
							0,;
							0,;
							Iif(!Empty(SA1->A1_XBLQLC),SA1->A1_XBLQLC,'2'),;
							Iif(ACY->(!Eof()),ACY->ACY_XBLPRZ,'2');
							})

					Else
						aListCli[nPos][06] += oMdlPaym:GetValue('L4_VALOR')
						If !(cForma $ aListCli[nPos][05])
							aListCli[nPos][05] += " + "+cForma
						EndIf

					EndIf

				EndIf

			Next nX

			oMdlPaym:GoLine(nPosMdl) //restauro a linha posicionada

			If Len(aListCli) > 0

				CursorArrow()

				STFMessage(ProcName(),"STOP","Pesquisando limite de crédito de venda do cliente"+iif(lRetOn .AND. cLCOffline <> "2"," no Back-Office","")+". Aguarde...")
				STFShowMessage(ProcName())

				CursorWait()

				aLimites := {}
				aParam := {}
				For nX:=1 to Len(aListCli)
					aadd(aParam,{aListCli[nX][02],aListCli[nX][03],""})
				Next nX
				aParam := {1,aParam}
				if lTP_ACTLCS
					aadd(aParam, cSegmento)
				endif
				if lRetOn .AND. cLCOffline <> "2" //so nao pesquisa online se parametro define apenas offline
					cHoraInicio := TIME() // Armazena hora de inicio do processamento...
					LjGrvLog("TRETE032", "INICIO - Retorna o limite utilizado de um CLIENTE e GRUPO DE CLIENTE",)

					aParam := {"U_TRETE032",aParam}
					If STBRemoteExecute("_EXEC_RET", aParam,,, @aLimites)
						If ValType(aLimites) == "A" .AND. Len(aLimites)>0
							For nX:=1 to Len(aLimites)

								//[01] [limite venda] ou [limite saque] UTILIZADO  do [Cliente] / [02] [limite venda] ou [limite saque] UTILIZADO  do [Grupo de Cliente]
								//[03] [limite venda] ou [limite saque] CADASTRADO do [Cliente] / [04] [limite venda] ou [limite saque] CADASTRADO do [Grupo de Cliente]
								//[05] [bloqueio venda] ou [bloqueio saque] do [Cliente]		/ [06] [bloqueio venda] ou [bloqueio saque] do [Grupo de Cliente]
								if Valtype(aLimites[nX]) == "A" .and. len(aLimites[nX]) >= 6
									aListCli[nX][08] := aLimites[nX][01]
									aListCli[nX][07] := aLimites[nX][03]
									aListCli[nX][13] := aLimites[nX][05]
									aListCli[nX][09] := aListCli[nX][07] - aListCli[nX][08] //saldo limite cliente

									aListCli[nX][11] := aLimites[nX][02]
									aListCli[nX][10] := aLimites[nX][04]
									aListCli[nX][14] := aLimites[nX][06]
									aListCli[nX][12] := aListCli[nX][10] - aListCli[nX][11] //saldo limite do grupo de cliente
								endif

							Next nX
						Else
							aLimites := {}
						EndIf
					Else
						aLimites := {}
					EndIf

					//LjGrvLog("TRETE032", "aLimites", aLimites)
					LjGrvLog("TRETE032", "Tempo de processamento: ", ElapTime( cHoraInicio, TIME() ))
					LjGrvLog("TRETE032", "FIM - Retorna o limite utilizado de um CLIENTE e GRUPO DE CLIENTE",)
				endif

				if empty(aLimites) .AND. cLCOffline <> "0" //so nao pesquisa offline se parametro define apenas online
					aLimites := U_TR032OFF(aParam[1],aParam[2],iif(lTP_ACTLCS,aParam[3],))
					For nX:=1 to Len(aLimites)
						//[01] [limite venda] ou [limite saque] UTILIZADO  do [Cliente] / [02] [limite venda] ou [limite saque] UTILIZADO  do [Grupo de Cliente]
						//[03] [limite venda] ou [limite saque] CADASTRADO do [Cliente] / [04] [limite venda] ou [limite saque] CADASTRADO do [Grupo de Cliente]
						//[05] [bloqueio venda] ou [bloqueio saque] do [Cliente]		/ [06] [bloqueio venda] ou [bloqueio saque] do [Grupo de Cliente]
						if Valtype(aLimites[nX]) == "A" .and. len(aLimites[nX]) >= 6
							aListCli[nX][08] := aLimites[nX][01]
							aListCli[nX][07] := aLimites[nX][03]
							aListCli[nX][13] := aLimites[nX][05]
							aListCli[nX][09] := aListCli[nX][07] - aListCli[nX][08] //saldo limite cliente

							aListCli[nX][11] := aLimites[nX][02]
							aListCli[nX][10] := aLimites[nX][04]
							aListCli[nX][14] := aLimites[nX][06]
							aListCli[nX][12] := aListCli[nX][10] - aListCli[nX][11] //saldo limite do grupo de cliente
						endif
					Next nX
				endif

				CursorArrow()

				STFMessage(ProcName(),"STOP","Analisando credito cliente. Aguarde...")
				STFShowMessage(ProcName())

			EndIf

			//valida limite e bloqueio dos clientes/grupo
			For nX:=1 to Len(aListCli)

				//VALIDANDO BLOQUEIOS DE LIMITE PARA VENDA
				//bloqueio de limite de cliente
				If (empty(aListCli[nX][04]) .OR. cPriGrupo <> "1") .AND. aListCli[nX][13] == '1'
					cMsgErr := "Cliente "+AllTrim(Posicione("SA1",1,xFilial("SA1")+aListCli[nX][02]+aListCli[nX][03],"A1_NOME"))+" com bloqueio de crédito (PGTO EM "+AllTrim(aListCli[nX][05])+")."
					STFMessage(ProcName(),"STOP",cMsgErr)
					STFShowMessage(ProcName())

					if lAlcada .AND. lAlcLimit
						cMsgLibAlc := "Alçada de Bloqueio de Limite Credito de Venda - Cliente" + CRLF
						cMsgLibAlc += "Cliente: " + SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME + CRLF
						cMsgLibAlc += "Pagamento em: " + aListCli[nX][05] + CRLF
						cMsgLibAlc += "Valor Pagamento: " + cValToChar(aListCli[nX][06]) + CRLF

						//verifico alçada do prorio usuario
						lLibLim := LibAlcadaBlq(,cMsgLibAlc)
						//se nao liberou e ja chamou tela açada para alguma forma, tento com ultimo usuário
						if !lLibLim .AND. !empty(cUsrLibLim)
							lLibLim := LibAlcadaBlq(cUsrLibLim,cMsgLibAlc)
						endif
						if !lLibLim
							//solicita liberaçao de alçada de outro usuario
							lLibLim := TelaLibAlcada(1, cMsgErr+CRLF+"Solicite liberação por alçada de um supervisor.",,,,@cUsrLibLim,cMsgLibAlc)
							if !lLibLim
								STFMessage(ProcName(),"STOP", "Usuário não tem alçada para Liberar Venda de Cliente com Bloqueio de Crédito." )
								STFShowMessage(ProcName())
								Return .F.
							endif
						endif
					else
						if empty(cUsrLibVBL)
							U_TRETA37B("LIBVBL", "LIBERAR VENDA CLIENTE/GRUPO COM BLOQUEIO CREDITO")
							cUsrLibVBL := U_VLACESS1("LIBVBL", cGetCdUsr)
							If cUsrLibVBL == Nil .OR. Empty(cUsrLibVBL)
								STFMessage(ProcName(),"STOP", "Usuário não tem permissão de acesso para Liberar Venda de Cliente com Bloqueio de Crédito." )
								STFShowMessage(ProcName())
								Return .F.
							EndIf
						endif
					endif

				//bloqueio de limite de grupo de cliente
				ElseIf !Empty(aListCli[nX][04]) .and. aListCli[nX][14] == '1'

					cMsgErr := "Grupo de Cliente "+AllTrim(Posicione("ACY",1,xFilial("ACY")+aListCli[nX][04],"ACY_DESCRI"))+" com bloqueio de crédito (PGTO EM "+AllTrim(aListCli[nX][05])+")."
					STFMessage(ProcName(),"STOP",cMsgErr)
					STFShowMessage(ProcName())

					if lAlcada .AND. lAlcLimit
						cMsgLibAlc := "Alçada de Bloqueio de Limite Credito de Venda - Grupo" + CRLF
						cMsgLibAlc += "Cliente/Emitente: " + aListCli[nX][02] + "/" + aListCli[nX][03] + " - " + Posicione("SA1",1,xFilial("SA1")+aListCli[nX][02]+aListCli[nX][03],"A1_NOME") + CRLF
						cMsgLibAlc += "Grupo do Cliente: " + ACY->ACY_GRPVEN + " - " + ACY->ACY_DESCRI + CRLF
						cMsgLibAlc += "Pagamento em: " + aListCli[nX][05] + CRLF
						cMsgLibAlc += "Valor Pagamento: " + cValToChar(aListCli[nX][06]) + CRLF

						//verifico alçada do prorio usuario
						lLibLim := LibAlcadaBlq(,cMsgLibAlc)
						//se nao liberou e ja chamou tela açada para alguma forma, tento com ultimo usuário
						if !lLibLim .AND. !empty(cUsrLibLim)
							lLibLim := LibAlcadaBlq(cUsrLibLim,cMsgLibAlc)
						endif
						if !lLibLim
							//solicita liberaçao de alçada de outro usuario
							lLibLim := TelaLibAlcada(1, cMsgErr+CRLF+"Solicite liberação por alçada de um supervisor.",,,,@cUsrLibLim,cMsgLibAlc)
							if !lLibLim
								STFMessage(ProcName(),"STOP", "Usuário não tem alçada para Liberar Venda de Cliente com Bloqueio de Crédito." )
								STFShowMessage(ProcName())
								Return .F.
							endif
						endif
					else
						if empty(cUsrLibVBL)
							U_TRETA37B("LIBVBL", "LIBERAR VENDA CLIENTE/GRUPO COM BLOQUEIO CREDITO")
							cUsrLibVBL := U_VLACESS1("LIBVBL", cGetCdUsr)
							If cUsrLibVBL == Nil .OR. Empty(cUsrLibVBL)
								STFMessage(ProcName(),"STOP", "Usuário não tem permissão de acesso para Liberar Venda de Cliente com Bloqueio de Crédito." )
								STFShowMessage(ProcName())
								Return .F.
							EndIf
						endif
					endif

				EndIf

				//VALIDANOD VALORES DE LIMITE DE CREDITO
				//se valor da venda > saldo limite credito
				If (empty(aListCli[nX][04]) .OR. cPriGrupo <> "1") .AND. aListCli[nX][06] > aListCli[nX][09]

					cMsgErr := "Cliente "+AllTrim(Posicione("SA1",1,xFilial("SA1")+aListCli[nX][02]+aListCli[nX][03],"A1_NOME"))+" não possui limite de crédito (PGTO EM "+AllTrim(aListCli[nX][05])+"). Saldo de Limite: "+Alltrim(Transform(aListCli[nX][09],PesqPict("SL1","L1_VLRLIQ")))
					STFMessage(ProcName(),"STOP", cMsgErr)
					STFShowMessage(ProcName())

					if lAlcada .AND. lAlcLimit
						cMsgLibAlc := "Alçada de Limite Credito de Venda Excedido - Cliente" + CRLF
						cMsgLibAlc += "Cliente: " + SA1->A1_COD + "/" + SA1->A1_LOJA + " - " + SA1->A1_NOME + CRLF
						cMsgLibAlc += "Pagamento em: " + aListCli[nX][05] + CRLF

						//verifico alçada do prorio usuario
						lLibLim := LibAlcadaLim(,aListCli[nX][06], aListCli[nX][07], aListCli[nX][09],cMsgLibAlc)
						//se nao liberou e ja chamou tela açada para alguma forma, tento com ultimo usuário
						if !lLibLim .AND. !empty(cUsrLibLim)
							lLibLim := LibAlcadaLim(cUsrLibLim, aListCli[nX][06], aListCli[nX][07], aListCli[nX][09],cMsgLibAlc)
						endif
						if !lLibLim
							//solicita liberaçao de alçada de outro usuario
							lLibLim := TelaLibAlcada(2, cMsgErr+CRLF+"Solicite liberação por alçada de um supervisor.",aListCli[nX][06], aListCli[nX][07], aListCli[nX][09], @cUsrLibLim,cMsgLibAlc)
							if !lLibLim
								STFMessage(ProcName(),"STOP", "Usuário não tem alçada para Liberar Venda sem Saldo de Limite de Crédito." )
								STFShowMessage(ProcName())
								Return .F.
							endif
						endif
					else
						if empty(cUsrLibVSL)
							U_TRETA37B("LIBVSL", "LIBERAR VENDA CLIENTE/GRUPO SEM SALDO LIMITE DE CREDITO")
							cUsrLibVSL := U_VLACESS1("LIBVSL", cGetCdUsr)
							If cUsrLibVSL == Nil .OR. Empty(cUsrLibVSL)
								STFMessage(ProcName(),"STOP", "Usuário não tem permissão de acesso para Liberar Venda sem Saldo de Limite de Crédito." )
								STFShowMessage(ProcName())
								Return .F.
							EndIf
						endif
					endif

					//se tem grupo cliente e valor da venda > saldo limite credito do grupo
				ElseIf !Empty(aListCli[nX][04]) .and. aListCli[nX][06] > aListCli[nX][12]

					cMsgErr := "Grupo de Cliente "+AllTrim(Posicione("ACY",1,xFilial("ACY")+aListCli[nX][04],"ACY_DESCRI"))+" não possui limite de crédito (PGTO EM "+AllTrim(aListCli[nX][05])+"). Saldo de Limite: "+Alltrim(Transform(aListCli[nX][12],PesqPict("SL1","L1_VLRLIQ")))
					STFMessage(ProcName(),"STOP",cMsgErr)
					STFShowMessage(ProcName())

					if lAlcada .AND. lAlcLimit
						cMsgLibAlc := "Alçada de Limite Credito de Venda Excedido - Grupo" + CRLF
						cMsgLibAlc += "Cliente/Emitente: " + aListCli[nX][02] + "/" + aListCli[nX][03] + " - " + Posicione("SA1",1,xFilial("SA1")+aListCli[nX][02]+aListCli[nX][03],"A1_NOME") + CRLF
						cMsgLibAlc += "Grupo do Cliente: " + ACY->ACY_GRPVEN + " - " + ACY->ACY_DESCRI + CRLF
						cMsgLibAlc += "Pagamento em: " + aListCli[nX][05] + CRLF

						//verifico alçada do prorio usuario
						lLibLim := LibAlcadaLim(, aListCli[nX][06], aListCli[nX][10], aListCli[nX][12],cMsgLibAlc)
						if !lLibLim .AND. !empty(cUsrLibLim)
							lLibLim := LibAlcadaLim(cUsrLibLim, aListCli[nX][06], aListCli[nX][10], aListCli[nX][12],cMsgLibAlc)
						endif
						if !lLibLim
							//solicita liberaçao de alçada de outro usuario
							lLibLim := TelaLibAlcada(2, cMsgErr+CRLF+"Solicite liberação por alçada de um supervisor.",aListCli[nX][06], aListCli[nX][07], aListCli[nX][09],@cUsrLibLim,cMsgLibAlc)
							if !lLibLim
								STFMessage(ProcName(),"STOP", "Usuário não tem alçada para Liberar Venda sem Saldo de Limite de Crédito." )
								STFShowMessage(ProcName())
								Return .F.
							endif
						endif
					else
						if empty(cUsrLibVSL)
							U_TRETA37B("LIBVSL", "LIBERAR VENDA CLIENTE/GRUPO SEM SALDO LIMITE DE CREDITO")
							cUsrLibVSL := U_VLACESS1("LIBVSL", cGetCdUsr)
							If cUsrLibVSL == Nil .OR. Empty(cUsrLibVSL)
								STFMessage(ProcName(),"STOP", "Usuário não tem permissão de acesso para Liberar Venda sem Saldo de Limite de Crédito." )
								STFShowMessage(ProcName())
								Return .F.
							EndIf
						endif
					endif

				EndIf

			Next nX

		EndIf
	EndIf

	If lRet
		STFCleanMessage()
		STFCleanInterfaceMessage()
	EndIf

Return lRet

//----------------------------------------------------------------------
// chama tela de liberação por alçada
// nTipo: 1=Bloqueios Limite; 2=Valor Limite; 3=Troco
//----------------------------------------------------------------------
Static Function TelaLibAlcada(nTipo, cMsgErr, nVlrVenda, nVlrLim, nSaldoLim, cUsrLibLim, cMsgLibAlc)

	Local lRet := .F.
	Local lEscape := .T.
	Local aLogin
	Local cMsgUser := ""

	While lEscape
		aLogin := U_TelaLogin(cMsgUser+cMsgErr,iif(nTipo==3,"Liberar Troco","Limite Credito"), .T.)
		if empty(aLogin) //cancelou tela
			lEscape := .F.
		else
			if nTipo == 1 //bloqueio
				lRet := LibAlcadaBlq(aLogin[1],cMsgLibAlc)
				if lRet
					cUsrLibLim := aLogin[1]
				else
					cMsgUser := "Usuário "+Alltrim(aLogin[2])+" não possui alçada suficiente para Liberar Venda de cliente com Bloqueio de Crédito." + CRLF
				endif
			elseif nTipo == 2 //valor limite
				lRet := LibAlcadaLim(aLogin[1], nVlrVenda, nVlrLim, nSaldoLim,cMsgLibAlc)
				if lRet
					cUsrLibLim := aLogin[1]
				else
					cMsgUser := "Usuário "+Alltrim(aLogin[2])+" não possui alçada suficiente para Liberar Venda sem Saldo de Limite de Crédito." + CRLF
				endif
			else //troco
				lRet := LibAlcadaTrc(aLogin[1],cMsgLibAlc, nVlrVenda, nSaldoLim )
				if !lRet
					cMsgUser := "Usuário "+Alltrim(aLogin[2])+" não possui alçada suficiente para Liberar Troco da Venda." + CRLF
				endif
			endif
			lEscape := !lRet
		endif
	enddo

Return lRet

//----------------------------------------------------------------------
// Verifica alçada de limite de credito
//----------------------------------------------------------------------
Static Function LibAlcadaLim(cCodUsr, nVlrVenda, nVlrLim, nSaldoLim, cMsgLog)

	Local nZ
	Local lRet := .F.
	Local nVlrLimAlc := 0
	Local nPerLimAlc := 0
	Default cCodUsr := RetCodUsr()
	Default cMsgLog := ""

	cMsgLog += "Valor Pagamento: " + cValToChar(nVlrVenda) + CRLF
	cMsgLog += "Valor Limite Credito: " + cValToChar(nVlrLim) + CRLF
	cMsgLog += "Saldo Limite Credito: " + cValToChar(nSaldoLim) + CRLF

	If cCodUsr == '000000' //usuario administrador, libera tudo
		lRet := .T.
	else
		//sero o saldo caso ele seja negativo
		if nSaldoLim < 0
			nSaldoLim := 0
		endif

		aGrupos := UsrRetGrp(UsrRetName(cCodUsr), cCodUsr)

		nVlrLimAlc := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_VNOLIM")
		nPerLimAlc := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_PNOLIM")

		// limite alçaca >= saldo sem limite				x % do limite >= saldo sem limite
		if (nVlrLimAlc >= (nVlrVenda - nSaldoLim)) .OR. ( (nVlrLim*nPerLimAlc/100) >= (nVlrVenda - nSaldoLim) )
			lRet := .T.
			cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
			cMsgLog += "Vlr Limite Alçada: " + cValToChar(nVlrLimAlc) + CRLF
			cMsgLog += "% Limite Alçada: " + cValToChar(nPerLimAlc) + CRLF
			cMsgLog += "Vlr obtido do % Limite: " + cValToChar((nVlrLim*nPerLimAlc/100)) + CRLF
		endif

		if !lRet
			for nZ := 1 to len(aGrupos)
				nVlrLimAlc := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_VNOLIM")
				nPerLimAlc := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_PNOLIM")

				// limite alçaca >= saldo sem limite				% do limite >= saldo sem limite
				if (nVlrLimAlc >= (nVlrVenda - nSaldoLim)) .OR. ( (nVlrLim*nPerLimAlc/100) >= (nVlrVenda - nSaldoLim) )
					lRet := .T.
					cMsgLog += "Grupo de Usuário Liberação: " + aGrupos[nZ] + " - " + GrpRetName(aGrupos[nZ]) + CRLF
					cMsgLog += "Vlr Limite Alçada: " + cValToChar(nVlrLimAlc) + CRLF
					cMsgLog += "% Limite Alçada: " + cValToChar(nPerLimAlc) + CRLF
					cMsgLog += "Vlr obtido do % Limite: " + cValToChar((nVlrLim*nPerLimAlc/100)) + CRLF
					EXIT
				endif
			next nZ
		endif
	endif

	//para gravaçao do log alçada
	if lRet
		U_AddLogAl("ALCLIM", USRRETNAME(cCodUsr), cMsgLog )
	endif

Return lRet

//----------------------------------------------------------------------
// Verifica alçada de bloqueio de credito
//----------------------------------------------------------------------
Static Function LibAlcadaBlq(cCodUsr, cMsgLog)

	Local nZ
	Local lRet := .F.
	Default cCodUsr := RetCodUsr()
	Default cMsgLog := ""

	If cCodUsr == '000000' //usuario administrador, libera tudo
		lRet := .T.
		cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
	else
		aGrupos := UsrRetGrp(UsrRetName(cCodUsr), cCodUsr)

		cLimBlq := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_VDCBLQ")
		if cLimBlq == "S"
			lRet := .T.
			cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
		endif

		if !lRet
			for nZ := 1 to len(aGrupos)
				cLimBlq := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_VDCBLQ")
				if cLimBlq == "S"
					lRet := .T.
					cMsgLog += "Grupo de Usuário Liberação: " + aGrupos[nZ] + " - " + GrpRetName(aGrupos[nZ]) + CRLF
					EXIT
				endif
			next nZ
		endif
	endif

	//para gravaçao do log alçada
	if lRet
		cMsgLog += "Campo U0D_VDCBLQ = S"
		U_AddLogAl("ALCLIM", USRRETNAME(cCodUsr), cMsgLog )
	endif

Return lRet

//--------------------------------------------------------------------
// Tela validação de composição do troco
//--------------------------------------------------------------------
Static Function CompTroco()

	Local lHabTroco := SuperGetMV("MV_LJTROCO",,.F.) 	//Habilita troco
	Local nTroco := STBGetTroco()

	nValorDi := nTroco
	nValorCh := 0
	nValorVl := 0

	nQtdCht := U_CHTEmpty()
	lActiveCHT := SuperGetMV("TP_ACTCHT",,.F.) .AND. nQtdCht > 0
	lActiveVLH := SuperGetMV("TP_ACTVLH",,.F.)

	If nTroco <= 0 .or. lSTConfSale
		lSTConfSale := .F.
		Return .T.
	EndIf

	//TODO - AJUSTE TEMPORARIO: "FORÇA" GRAVA O VALOR DO TROCO (ESTA COM *PAU* NO PADRÃO PARA OUTRAS FORMAS DIFERENTE DE R$/CH/CC/CD)
	If lHabTroco .And. nTroco > 0
		STDSPBasket("SL1", "L1_TROCO1", nTroco)
	EndIf

	//STIExchangePanel( {|| TelaTroco(nTroco) } )
	TelaTroco(nTroco)

	oValorDi:SetFocus()

Return .F.

//-------------------------------------------------------------------
/*/{Protheus.doc} TelaTroco
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function TelaTroco(nTroco)

	Local oPanelMVC	:= Nil //STIGetPanel() //Painel do MVC	Painel de botoes
	Local nWidth, nHeight
	Local nTamBut := 80

	Local _nValorDi := nTroco
	Local _nValorCh := 0
	Local _nValorVl := 0

	nMaxTroco := U_TPDVE04A() //Valor máximo de troco permito em dinhiero/cheque [ R$ + CH ]
	nMaxTroco := iif(nMaxTroco>nTroco,nTroco,nMaxTroco)
	nTrocTot  := nTroco	

	//ajusto o troco em vale caso o troco total for menor que o maximo de troco em dinheiro
	if lActiveVLH .AND. nMaxTroco < nTroco
		if ValidTr(4, nMaxTroco, nValorCh, nTroco - nMaxTroco)
			nValorDi := nMaxTroco
			nValorVl := nTroco - nMaxTroco
			_nValorDi := nMaxTroco
			_nValorVl := nTroco - nMaxTroco
		endif
	endif

	if oPnlCompTrc == Nil
		oPanelMVC := STIGetDlg() //STIGetPanel()

		nWidth  := (oPanelMVC:nWidth/2)
		nHeight := (oPanelMVC:nHeight/2)-72

		oPnlCompTrc := TPanel():New(070,00,"",oPanelMVC,,,,,,nWidth,nHeight) //Painel do composição de troco
		oPnlCompTrc:SetCSS( POSCSS (GetClassName(oPnlCompTrc), CSS_PANEL_CONTEXT ))

		/* Label: Pagamento */
		oSay1 := TSay():New(POSVERT_CAB, POSHOR_1, {|| "Composição de Troco"}, oPnlCompTrc,,,,,,.T.,,,100,11.5)
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))

		@ 025, 015 SAY oSay1 PROMPT "Dinheiro R$" SIZE 070, 008 OF oPnlCompTrc COLORS 0, 16777215 PIXEL
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
		oValorDi := TGet():New( 035, 015,{|u| if( PCount()>0,nValorDi:=u,nValorDi)}, oPnlCompTrc, 085, 015, PesqPict("SL4","L4_VALOR"),{|| ValidTr(1,@_nValorDi,@_nValorCh,@_nValorVl) },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,,,,,.F.,.T.)
		oValorDi:SetCSS( POSCSS (GetClassName(oValorDi), CSS_GET_NORMAL ))

		@ 055, 015 SAY oSay1 PROMPT "Cheque Troco" SIZE 070, 008 OF oPnlCompTrc COLORS 0, 16777215 PIXEL
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
		oValorCh := TGet():New( 065, 015,{|u| if( PCount()>0,nValorCh:=u,nValorCh)}, oPnlCompTrc, 085, 015, PesqPict("SL4","L4_VALOR"),{|| ValidTr(2,@_nValorDi,@_nValorCh,@_nValorVl) },,,,,,.T.,,,{|| .T. },,,,!lActiveCHT,.F.,,,,,,.F.,.T.)
		oValorCh:SetCSS( POSCSS (GetClassName(oValorCh), CSS_GET_NORMAL ))

		@ 068, 105 SAY oSay1 PROMPT (cValToChar(nQtdCht)+" cheques disponíveis") SIZE 150, 012 OF oPnlCompTrc COLORS 0, 16777215 PIXEL
		oSay1:SetCSS( POSCSS (GetClassName(oSay1),CSS_BREADCUMB ))

		@ 085, 015 SAY oSay1 PROMPT "Vale Haver" SIZE 070, 008 OF oPnlCompTrc COLORS 0, 16777215 PIXEL
		oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
		oValorVl := TGet():New( 095, 015,{|u| if( PCount()>0,nValorVl:=u,nValorVl)}, oPnlCompTrc, 085, 015, PesqPict("SL4","L4_VALOR"),{|| ValidTr(3,@_nValorDi,@_nValorCh,@_nValorVl) },,,,,,.T.,,,{|| .T. },,,,!lActiveVLH,.F.,,,,,,.F.,.T.)
		oValorVl:SetCSS( POSCSS (GetClassName(oValorVl), CSS_GET_NORMAL ))

		/* Label: Total Troco */
		oLblTotTroc := TSay():New(nHeight-88, nWidth-060, {|| "Troco Total"}, oPnlCompTrc,,,,,,.T.,,,050,9)
		oLblTotTroc:SetCSS( POSCSS (GetClassName(oLblTotTroc),CSS_BREADCUMB ))

		/* Label: 0.00 */
		oLblValTroc := TGet():New( nHeight-80, nWidth-115,{|u| if( PCount()>0,nTrocTot:=u,nTrocTot)}, oPnlCompTrc, 100, 010, PesqPict("SL4","L4_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,,,,,.F.,.T.)
		oLblValTroc:lCanGotFocus := .F.
		oLblValTroc:SetCSS( POSCSS (GetClassName(oLblValTroc), CSS_LABEL_FOCAL ))

		/* Label: Troco Maximo: R$ + CH */
		oLblTrocMax := TSay():New(nHeight-63, nWidth-120, {|| "Troco Máximo: [ R$ + CH ]"}, oPnlCompTrc,,,,,,.T.,,,115,9)
		oLblTrocMax:SetCSS( POSCSS (GetClassName(oLblTrocMax),CSS_BREADCUMB ))

		/* Label: 0.00 */
		oLblValMaxi := TGet():New( nHeight-55, nWidth-115,{|u| if( PCount()>0,nMaxTroco:=u,nMaxTroco)}, oPnlCompTrc, 100, 010, PesqPict("SL4","L4_VALOR"),{|| .T. },,,,,,.T.,,,{|| .T. },,,,.T.,.F.,,,,,,.F.,.T.)
		oLblValMaxi:lCanGotFocus := .F.
		oLblValMaxi:SetCSS( POSCSS (GetClassName(oLblValMaxi), CSS_LABEL_FOCAL ))

		// BOTAO CONFIRMAR
		oBtn1 := TButton():New( nHeight-35,;
			nWidth-nTamBut-5,;
			"&Confirmar"+CRLF+"(ALT+C)",;
			oPnlCompTrc	,;
			{|| ValidaCheck() },; //fazer gravação nos componentes do totvs pdv, ou preparar retorno para PE
		nTamBut,;
			025,;
			,,,.T.,;
			,,,{|| .T.})
		oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

		// BOTAO CANCELAR
		oBtn2 := TButton():New( nHeight-35,;
			nWidth-(2*nTamBut)-10,;
			"C&ancelar"+CRLF+"(ALT+A)",;
			oPnlCompTrc	,;
			{|| oPnlCompTrc:hide(), CleanVar()},; //STIPayCancel(), 
			nTamBut,;
			025,;
			,,,.T.,;
			,,,{|| .T.})
		oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_ATIVO ))
	else
		oPnlCompTrc:Show()
		oPnlCompTrc:Refresh()
	endif

Return oPnlCompTrc

//--------------------------------------------------------------------
// Valida valor digitado
//--------------------------------------------------------------------
Static Function ValidTr(nOpc,_nValorDi,_nValorCh,_nValorVl)

	Local lRet := .T.
	Local nTroco := STBGetTroco()

	Local oCliModel := STDGCliModel() 				// Model do Cliente
	Local cCliente  := oCliModel:GetValue("SA1MASTER","A1_COD")
	Local cLojaCli  := oCliModel:GetValue("SA1MASTER","A1_LOJA")
	Local cCliPadr	:= SuperGetMv("MV_CLIPAD") 	// Cliente padrao
	Local cLojaPad	:= SuperGetMV("MV_LOJAPAD") // Loja padrao

	If nOpc == 1 .and. _nValorDi <> oValorDi:cText //dinheiro

		If oValorDi:cText > nTroco
			STFMessage( ProcName(), "STOP", "Valor não pode ser maior que o troco total:"+" "+AllTrim(Str(nTroco,10,2))+" "+"" )
			STFShowMessage(ProcName())
			lRet := .F.

		ElseIf oValorDi:cText > nMaxTroco
			STFMessage( ProcName(), "STOP", "O troco em DINHEIRO + CHEQUE TROCO está acima do valor máximo de troco permitido:"+" "+AllTrim(Str(nMaxTroco,10,2))+" "+"" )
			STFShowMessage(ProcName())
			//lRet := .F.

		ElseIf oValorDi:cText == nTroco
			oValorCh:cText := 0
			oValorVl:cText := 0

		ElseIf oValorDi:cText > _nValorDi + oValorCh:cText
			oValorCh:cText := nTroco - oValorDi:cText
			oValorVl:cText := 0

		Else
			oValorCh:cText := nTroco - oValorDi:cText - oValorVl:cText

		EndIf

	ElseIf nOpc == 2 .and. _nValorCh <> oValorCh:cText //cheque

		If oValorCh:cText > nTroco
			STFMessage( ProcName(), "STOP", "Valor não pode ser maior que o troco total:"+" "+AllTrim(Str(nTroco,10,2))+" "+"" )
			STFShowMessage(ProcName())
			lRet := .F.

		ElseIf oValorCh:cText > nMaxTroco
			STFMessage( ProcName(), "STOP", "O troco em DINHEIRO + CHEQUE TROCO está acima do valor máximo de troco permitido:"+" "+AllTrim(Str(nMaxTroco,10,2))+" "+"" )
			STFShowMessage(ProcName())
			//lRet := .F.

		ElseIf oValorCh:cText == nTroco
			oValorDi:cText := 0
			oValorVl:cText := 0

		ElseIf (cCliente + cLojaCli == cCliPadr + cLojaPad)
			oValorDi:cText := nTroco - oValorCh:cText
			oValorVl:cText := 0

		ElseIf oValorCh:cText > oValorDi:cText + _nValorCh
			oValorDi:cText := nTroco - oValorCh:cText
			oValorVl:cText := 0

		Else
			oValorDi:cText := nTroco - oValorCh:cText - oValorVl:cText

		EndIf

		If lRet
			oValorDi:cText := nTroco - oValorCh:cText - oValorVl:cText
		EndIf

	ElseIf nOpc == 3  .and. _nValorVl <> oValorVl:cText //vale haver

		If (cCliente + cLojaCli == cCliPadr + cLojaPad) .and. oValorVl:cText > 0
			STFMessage(ProcName(),"STOP","Cliente padrão não habilitado para troco em Vale Haver!" )
			STFShowMessage(ProcName())
			lRet := .F.

		ElseIf oValorVl:cText > nTroco
			STFMessage( ProcName(), "STOP", "Valor não pode ser maior que o troco total:"+" "+AllTrim(Str(nTroco,10,2))+" "+"" )
			STFShowMessage(ProcName())
			lRet := .F.

		ElseIf (oValorVl:cText > oValorDi:cText) .and. (nTroco - oValorVl:cText) > nMaxTroco
			STFMessage( ProcName(), "STOP", "O troco em DINHEIRO + CHEQUE TROCO está acima do valor máximo de troco permitido:"+" "+AllTrim(Str(nMaxTroco,10,2))+" "+"" )
			STFShowMessage(ProcName())
			//lRet := .F.

		ElseIf (oValorDi:cText - oValorVl:cText) > nMaxTroco
			STFMessage( ProcName(), "STOP", "O troco em DINHEIRO + CHEQUE TROCO está acima do valor máximo de troco permitido:"+" "+AllTrim(Str(nMaxTroco,10,2))+" "+"" )
			STFShowMessage(ProcName())
			//lRet := .F.

		ElseIf oValorVl:cText == nTroco
			oValorDi:cText := 0
			oValorCh:cText := 0

		ElseIf oValorVl:cText > oValorDi:cText
			oValorCh:cText := 0
			oValorDi:cText := nTroco - oValorVl:cText

		Else
			oValorDi:cText := oValorDi:cText - oValorVl:cText

		EndIf

		If lRet
			oValorDi:cText := nTroco - oValorCh:cText - oValorVl:cText
		EndIf
	
	elseif nOpc == 4 //verifico se troco pode ser em vale haver
		If (cCliente + cLojaCli == cCliPadr + cLojaPad) //nao pode para consumidor
			lRet := .F.
		endif
	EndIf

	If lRet .and. nOpc != 4 .and. (_nValorDi <> oValorDi:cText .or. _nValorCh <> oValorCh:cText .or. _nValorVl <> oValorVl:cText )

		_nValorDi := oValorDi:cText
		_nValorCh := oValorCh:cText
		_nValorVl := oValorVl:cText

		oValorDi:Refresh()
		oValorCh:Refresh()
		oValorVl:Refresh()

	EndIf

Return lRet

//--------------------------------------------------------------------
// Valida o botão confirma
//--------------------------------------------------------------------
Static Function ValidaCheck()

	Local lRet := .T.
	Local nTroco := STBGetTroco()
	Local aRecebtos := {}
	Local nI
	Local oMdl 		:= STISetMdlPay()			 //Get no objeto oModel: Resumo do Pagamento
	Local oModel	:= oMdl:GetModel('PARCELAS') //Get no model parcelas
	Local nPosMdl
	Local aTotUlForma := {"",0}

	Local oCliModel := STDGCliModel() 				// Model do Cliente
	Local cCliente  := oCliModel:GetValue("SA1MASTER","A1_COD")
	Local cLojaCli  := oCliModel:GetValue("SA1MASTER","A1_LOJA")
	Local cCliPadr	:= SuperGetMv("MV_CLIPAD") 	// Cliente padrao
	Local cLojaPad	:= SuperGetMV("MV_LOJAPAD") // Loja padrao

	Local cMsgErr := ""
	Local lAlcada	:= SuperGetMv("ES_ALCADA",.F.,.F.)
	Local lAlcTroc	:= SuperGetMv( "ES_ALCTRC",.F.,.F.)
	Local cMsgLibAlc := ""
	Local lLibTRC := .F.

	If nTroco <= 0
		CleanVar()
		oPnlCompTrc:hide()
		Return lRet
	EndIf

	If (cCliente + cLojaCli == cCliPadr + cLojaPad) .and. oValorVl:cText > 0
		STFMessage(ProcName(),"STOP","Cliente padrão não habilitado para troco em Vale Haver!" )
		STFShowMessage(ProcName())
		lRet := .F.

	ElseIf oValorDi:cText + oValorCh:cText + oValorVl:cText > nTroco
		STFMessage( ProcName(), "STOP", "Valores da composição ultrapassam o troco total:"+" "+AllTrim(Str(nTroco,10,2))+" "+"" )
		STFShowMessage(ProcName())
		lRet := .F.

	ElseIf oValorDi:cText + oValorCh:cText + oValorVl:cText < nTroco
		STFMessage( ProcName(), "STOP", "Valores da composição são menores que o troco total:"+" "+AllTrim(Str(nTroco,10,2))+" "+"" )
		STFShowMessage(ProcName())
		lRet := .F.

	ElseIf oValorDi:cText + oValorCh:cText > nMaxTroco
		cMsgErr := "O troco em DINHEIRO + CHEQUE TROCO está acima do valor máximo de troco permitido:"+" "+AllTrim(Str(nMaxTroco,10,2))+" "+""
		STFMessage( ProcName(), "STOP", cMsgErr )
		STFShowMessage(ProcName())

		if lAlcada .AND. lAlcTroc

			//carregar o total recebido da ultima forma
			If ValType(oModel) == "O"
				nPosMdl := oModel:GetLine() //:nLine
				oModel:GoLine(oModel:Length()) //vai para ultima forma
				aTotUlForma := { oModel:GetValue('L4_FORMA'), oModel:GetValue('L4_VALOR') } 
				oModel:GoLine(nPosMdl)
			EndIf

			cMsgLibAlc := "Alçada de Máximo de Troco da Venda" + CRLF
			cMsgLibAlc += "Troco DH + CHT Informado: " + cValToChar( oValorDi:cText + oValorCh:cText ) + CRLF
			cMsgLibAlc += "Pagamento em: " + aTotUlForma[1] + CRLF
			cMsgLibAlc += "Valor Pagamento: " + cValToChar(aTotUlForma[2]) + CRLF
			cMsgLibAlc += "Maximo Troco Permitido: " + cValToChar(nMaxTroco) + CRLF

			//verifico alçada do prorio usuario
			lLibTRC := LibAlcadaTrc(,cMsgLibAlc, aTotUlForma[2], oValorDi:cText + oValorCh:cText )
			if !lLibTRC
				//solicita liberaçao de alçada de outro usuario
				lLibTRC := TelaLibAlcada(3, cMsgErr+CRLF+"Solicite liberação por alçada de um supervisor.",aTotUlForma[2],,oValorDi:cText + oValorCh:cText,,cMsgLibAlc)
				if !lLibTRC
					STFMessage(ProcName(),"STOP", "Usuário não tem alçada para Liberar Troco acima do maximo permitido." )
					STFShowMessage(ProcName())
					Return .F.
				endif
			endif
		else
			lRet := .F.
		endif
		
	EndIf

	//valida vale haver
	If lRet

		/*
		//ATENCAO -> nao alterar a ordem do array abaixo
		Array aRecebtos
		{	Forma,            -> [1]
			Condicao,         -> [2]
			Administradora,   -> [3] ou Emit.Cheque
			Padrão?,		  -> [4]
					{[01] - Item,
					 [02] - Produto,
					 [03] - Qtd,
					 [04] - Prc Pad.,
					 [05] - Prc Util,
					 [06] - LimTrocoU25,
					 [07] - VlrMaxU25,
					 [08] - %MaxU25,
					 [09] - RecnoU25,
					 [10] - Prc Neg,
					 [11] - Vlr Max Desc, 	//valor desconto maximo
					 [12] - % Max Desc, 	//percentual desconto maximo
					 [13] - % Marg Min, 	//margem minima
					 [14] - Custo Prod, 	//custo do produto
					 [15] - Bloq Alcada,
					 [16] - Usuario,
					 			} {Item, Produto,...} {?}, -> [5]
			Total Item Cupom, -> [6]
			Total Forma Pgto, -> [7]
			Total Desconto,	  -> [8]
			Recebido,		  -> [9]
			Percentual,		  -> [10]
			Saldo,			  -> [11]
			Original,		  -> [12]
			Desconto,		  -> [13]
			Saldo Outros,	  -> [14]
			{LimTroco, VlrMax, %Max, Perm.Vha}, -> [15] //maximo troco U44
			Troco			  -> [16]
		}
		*/
		aRecebtos := U_GetReceb()

		For nI := 1 To Len(aRecebtos)

			If aRecebtos[nI][9] > 0 //forma foi utilizada

				If aRecebtos[nI][15][4] <> "S" .And. oValorVl:cText > 0 //não permite Vale Haver E foi informado valor de troca em Vale Haver

					STFMessage( ProcName(), "STOP", "Para a forma de pagamento selecionada "+AllTrim(aRecebtos[nI][1])+", não é permitido troco em Vale Haver" )
					STFShowMessage(ProcName())
					lRet := .F.
					Exit
				EndIf
			EndIf
		Next nI
	EndIf

	If lRet

		//gravacao do troco em cheque troco
		If SL1->(FieldPos("L1_XTROCCH")) > 0
			STDSPBasket("SL1","L1_XTROCCH", oValorCh:cText )
		EndIf

		//gravacao do troco em vale haver
		If SL1->(FieldPos("L1_XTROCVL")) > 0
			STDSPBasket("SL1","L1_XTROCVL", oValorVl:cText )
		EndIf

		lSTConfSale := .T.

		oPnlCompTrc:hide()

		//-- chamar rotina novamente de "Finalizar pagamento"
		STIConfPay(,"Click")

	EndIf

Return lRet

//----------------------------------------------------------------------------------------
// Faz liberação do troco por alçada
//----------------------------------------------------------------------------------------
Static Function LibAlcadaTrc(cCodUsr, _cMsgLog, nVlrReceb, nTrocoDin)

	Local nZ
	Local lRet := .F.
	Local nVlrMaxAlc := 0
	Local nVMaxTroco := 0
	Local nPMaxTroco := 0
	Local cMsgLog := _cMsgLog
	Default cCodUsr := RetCodUsr()

	if U0D->(FieldPos("U0D_VMAXTR")) == 0 .OR. U0D->(FieldPos("U0D_PMAXTR")) == 0
		Return .F.
	endif

	If cCodUsr == '000000' //usuario administrador, libera tudo
		lRet := .T.
		cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
	else
		aGrupos := UsrRetGrp(UsrRetName(cCodUsr), cCodUsr)

		//pego o valor maximo de troco e o percentual
		nVMaxTroco := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_VMAXTR")
		nPMaxTroco := Posicione("U0D",1,xFilial("U0D")+Space(TamSx3("U04_GRUPO")[1])+PadR(cCodUsr,TamSx3("U04_USER")[1]),"U0D_PMAXTR")
		nVlrMaxAlc := nVlrReceb * nPMaxTroco / 100 //calculo o valor maximo pelo percentual
		if nVMaxTroco < nVlrMaxAlc //se o valor da alçada for menor que o calculado, substituo
			nVlrMaxAlc := nVMaxTroco
		endif

		if nVlrMaxAlc >= nTrocoDin
			lRet := .T.
			cMsgLog += "Usuário Liberação: " + cCodUsr + " - " + USRRETNAME(cCodUsr) + CRLF
		endif

		if !lRet
			for nZ := 1 to len(aGrupos)
				//pego o valor maximo de troco e o percentual
				nVMaxTroco := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_VMAXTR")
				nPMaxTroco := Posicione("U0D",1,xFilial("U0D")+PadR(aGrupos[nZ],TamSx3("U04_GRUPO")[1])+Space(TamSx3("U04_USER")[1]),"U0D_PMAXTR")
				nVlrMaxAlc := nVlrReceb * nPMaxTroco / 100 //calculo o valor maximo pelo percentual
				if nVMaxTroco < nVlrMaxAlc //se o valor da alçada for menor que o calculado, substituo
					nVlrMaxAlc := nVMaxTroco
				endif

				if nVlrMaxAlc >= nTrocoDin
					lRet := .T.
					cMsgLog += "Grupo de Usuário Liberação: " + aGrupos[nZ] + " - " + GrpRetName(aGrupos[nZ]) + CRLF
				endif
			next nZ
		endif
	endif

	//para gravaçao do log alçada
	if lRet
		cMsgLog += "Valor Maximo Troco Usuário Alçada: " + cValToChar(nVlrMaxAlc) + CRLF
		U_AddLogAl("ALCTRC", USRRETNAME(cCodUsr), cMsgLog )
	endif

Return lRet

//------------------------------------------
//valida data abastecimeno dia anterior
//------------------------------------------
Static Function VldDtAbast()

	Local lRet := .T.
	Local lVldDtAba := SuperGetMv("MV_VLDDTAB",,.F.) //habilita validacao data do abastecimento, dia anterior
	Local dMvDtVAba 
	Local aRet := {}, aParam := {}
	Local dDtMID := STOD("")
	Local oModelCesta 	:= STDGPBModel() // Model da cesta
	Local oModelSL2
	Local nI

	dDtVAba := STOD("")

	if lVldDtAba
		dMvDtVAba := STOD(GetMv("MV_DTUVABA")) //ultima data validada

		//buscar maior data dos abastecimentos da venda atual
		oModelSL2 := oModelCesta:GetModel("SL2DETAIL")
		For nI := 1 To oModelSL2:Length()
			oModelSL2:GoLine(nI)
			If !oModelSL2:IsDeleted() .AND. !empty(oModelSL2:GetValue('L2_MIDCOD'))
				if Posicione("MID",1,xFilial("MID")+oModelSL2:GetValue('L2_MIDCOD'), "MID_DATACO") > dDtMID
					dDtMID := MID->MID_DATACO
				endif
			endif
		next nX

		//data abastecimento é maior que da ultima verificacao?
		if !empty(dDtMID) .AND. (empty(dMvDtVAba) .OR. dDtMID > dMvDtVAba)

			CursorArrow()
			CursorWait()
			STFMessage("TPDVP017","STOP", "Validando abastecimentos dia anterior..." )
			STFShowMessage("TPDVP017")

			aParam := { ""/*bico*/, {"MID_DATACO"}/*campos*/, "MID_DATACO < '"+DTOS( dDtMID )+"' AND MID_XDIVER = '1' "/*filtro*/ }
			aParam := {"U_TPDVA09A",aParam}
			If !FWHostPing() .OR. !STBRemoteExecute("_EXEC_CEN",aParam,,,@aRet)
				//Conout("TPDVP006: Falha de comunicação com a central...")
			ElseIf aRet = Nil .OR. Valtype(aRet)<>"A"
				//Conout("TPDVP006: Ocorreu falha na consulta de abastecimentos na central...")
			Else //-- consulta realizada com sucesso
				If Len(aRet) > 0 //se tem abastecimentos
					Aviso( "Atenção!","Há abastecimento(s) do dia "+ DTOC(aRet[1][1]) +" pendente(s) de baixa. Favor baixar todos abastecimentos do dia anterior primeiro.", {"Ok"} )
					lRet := .F.
				else
					// guardo data para gravar no parametro
					dDtVAba := dDtMID
				endif
			EndIf
		endif

		CursorArrow()
		STFCleanMessage()
		STFCleanInterfaceMessage()
	endif

Return lRet

//--------------------------------------------------------------------
// Função para limpar os objetos Static da criação da tela
//--------------------------------------------------------------------
Static Function CleanVar()

	lSTConfSale := .F.
	nMaxTroco   := 0
	nTrocTot	:= 0

	oValorDi:cText := 0
	oValorCh:cText := 0
	oValorVl:cText := 0

Return .T.

User Function GSDtVAba()
Return dDtVAba
