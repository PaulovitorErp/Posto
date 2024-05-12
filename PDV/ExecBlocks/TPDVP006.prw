#include 'protheus.ch'
#include 'stpos.ch'
#include 'poscss.ch'

Static lWhenBtnNF := .T.
Static oBtnMsgNF
Static oPnlMsgNf
Static oMsgNf
Static cMsgNf := Space(150)
Static cBkpMsgNf

Static MIDPBIO      := 19 // % Biodiesel
Static MIDINDIMP    := 20 //Indic Import
Static MIDUFORIG    := 21 //UF Orig
Static MIDPORIG     := 22 //% UF Origem
Static MIDCODANP    := 23 //Codigo ANP

/*/{Protheus.doc} TPDVP006
Função utilizada pelo Ponto de Entrada StValPro

@author Maiki Perin
@since 18/09/2018
@version P12
@param PARAMIXB
@return lRet
/*/
User Function TPDVP006()

	Local lRet 			:= .T.
	Local aAreaSA1		:= SA1->(GetArea())
	Local aAreaSB1		:= SB1->(GetArea())

	Local oCliModel 	:= STDGCliModel() // Model do Cliente
	Local cCliente  	:= oCliModel:GetValue("SA1MASTER","A1_COD")
	Local cLojaCli  	:= oCliModel:GetValue("SA1MASTER","A1_LOJA")

	Local cNomeCli		:= ""
	Local aGrpProd		:= {}
	Local aGrpRest		:= {}
	Local aProd			:= {}
	Local aProdRest		:= {}
	Local nI

	Local cCodItem		:= PARAMIXB[1] // Codigo do produto
	//Local nQuant		:= PARAMIXB[2] // Quantidade

	Local oModelCesta	:= STDGPBModel() // Model de venda
	Local oModelSL2		:= oModelCesta:GetModel("SL2DETAIL") // Model Itens Orc.

	Local cDescGrp		:= ""
	Local cDescProd		:= ""
	Local nContNGrp		:= 0
	Local nContNProd	:= 0

	Local oGetList, nPosAbast, nPos, nPosVend
	Local nMaxDiv		:= SuperGetMv("MV_XMAXDIV",,0)

	Local cL1Num	:= STDGPBasket("SL1" , "L1_NUM")
	Local cError := ""

	Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.)
	Local lMvVlIdent := SuperGetMv("TP_VLIDENT",,.F.) //valida identifid com o vendedor logado
	Local cVenIdent := ""

	Local lVldDtAba := SuperGetMv("MV_VLDDTAB",,.F.) //habilita validacao data do abastecimento, dia anterior
	Local dMvDtVAba
	Local aRet := {}, aParam := {}

	Local oModelVen, cCodVend := "", aAreaSA3
	Local cTpProd := SuperGetMv("MV_XTPPROD", Nil, "") //Lista de tipos de produtos que podem ser usados no PDV (Ex.: "ME/KT")

	Local nItemLine := 0 //Quantidade de itens na cesta
	Local nMaxItens := SuperGetMv("MV_XQTMPDV", Nil, 990) //Quantidade máxima de itens permitido no grid/cesta (default 990)

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).

	Local aSupplyFuel := {}
	Local nPosAux := 0

	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return lRet
	EndIf

	//Se está registrando a partir do grid de abastecimentos
	If IsInCallStack("STISelAbast")

		oGetList := STIGGridAbast() //pega o grid de abastecimentos
		If Valtype(oGetList) == "O"

			nPos		:= oGetList:nAt
			nPosAbast := aScan(oGetList:aHeader, {|x| Alltrim(x[2])=="MID_CODABA"})
			If !Empty(oGetList:aCols[nPos][nPosAbast])
				
				nPosVend := aScan(oGetList:aHeader, {|x| Alltrim(x[2])=="A3_NOME"})
				cVenIdent := SubStr(oGetList:aCols[nPos][nPosVend],1,TamSX3("A3_COD")[1])

				MID->(DbSetOrder(1)) //MID_FILIAL+MID_CODABA
				If MID->( DbSeek( xFilial("MID") + oGetList:aCols[nPos][nPosAbast] ) )

					//verifica se abastecimento ja está em uso por outro orçamento/venda
					If !U_PodeUseAbast(MID->MID_CODABA,cL1Num,@cError)

						Aviso( "Atenção!", cError, {"Ok"} )
						lRet := .F.

						// se o abastecimento for de diverência para mais
						// valido se a quantidade não é superior ao máximo permitido
					ElseIf MID->MID_XDIVER == "2" .AND. (nMaxDiv==0 .OR. MID->MID_LITABA > nMaxDiv)  //1=Nao;2= A mais;3=A menos

						Aviso( "Atenção!","O abastecimento " + AllTrim(MID->MID_CODABA) + " foi gerado a partir de uma diferença positiva de encerrante e ultrapassa o limite superior estabelecido. Não pode ser baixado. Contate o administrador do sistema!", {"Ok"} )
						lRet := .F.

					ElseIf MID->MID_XDIVER == "3" .AND. Empty(MID->MID_XMANUT) //1=Nao;2= A mais;3=A menos

						Aviso( "Atenção!","Houve uma diferença de encerrante a menor para o abastecimento " + AllTrim(MID->MID_CODABA) + ". Favor providenciar lançamento de manutenção e vincular a este abastecimento. Contate o administrador do sistema! ", {"Ok"} )
						lRet := .F.

						//Validacao baixar todos abastecimentos dia anterior
					ElseIf lVldDtAba
						//crio parametro caso nao exista
						If SuperGetMv("MV_DTUVABA",,"XXX") == "XXX"
							aParam := {{"MV_DTUVABA", "C", "Data ultima verificaçao abastecimento pendente dia anterior", "" }}
							U_zCriaPar(aParam)
						EndIf
						dMvDtVAba := STOD(GetMv("MV_DTUVABA")) //ultima data validada

						If (Empty(dMvDtVAba) .OR. MID->MID_DATACO > dMvDtVAba)
							CursorArrow()
							CursorWait()
							STFMessage("TPDVP006","STOP", "Validando abastecimentos dia anterior..." )
							STFShowMessage("TPDVP006")

							aParam := { ""/*bico*/, {"MID_DATACO"}/*campos*/, "MID_DATACO < '"+DTOS( MID->MID_DATACO )+"' .AND. MID_XDIVER = '1' "/*filtro*/ }
							aParam := {"U_TPDVA09A",aParam}
							If !FWHostPing() .OR. !STBRemoteExecute("_EXEC_CEN",aParam,,,@aRet)
								//Conout("TPDVP006: Falha de comunicação com a central...")
							ElseIf aRet = Nil .OR. Valtype(aRet)<>"A"
								//Conout("TPDVP006: Ocorreu falha na consulta de abastecimentos na central...")
							Else //-- consulta realizada com sucesso
								If Len(aRet) > 0 //se tem abastecimentos
									Aviso( "Atenção!","Há abastecimento(s) do dia anterior pendente(s) de baixa. Favor baixar todos abastecimentos do dia anterior primeiro.", {"Ok"} )
									lRet := .F.
								EndIf
							EndIf

							CursorArrow()
							STFCleanMessage()
							STFCleanInterfaceMessage()
						EndIf
					EndIf

					//tratativa para quanto usa Ordenar Grid no PE STIPSTGRID
					//Ao gravar a copia do abastecimento na base local PDV, está pegando a posição errada.
					if lRet 
						// Carrega variavel com os abastecimentos
						aSupplyFuel := STDGSupplyFuel()
						nPosAux := aScan(aSupplyFuel, {|aAbast| aAbast[01] == oGetList:aCols[nPos][nPosAbast] })
						if nPosAux > 0
							If RecLock('MID',.F.)
								MID->MID_PBIO	:= aSupplyFuel[nPosAux][MIDPBIO]
								MID->MID_INDIMP	:= aSupplyFuel[nPosAux][MIDINDIMP]
								MID->MID_UFORIG	:= aSupplyFuel[nPosAux][MIDUFORIG]
								MID->MID_PORIG	:= aSupplyFuel[nPosAux][MIDPORIG]
								MID->MID_CODANP	:= aSupplyFuel[nPosAux][MIDCODANP]

								MID->(MsUnlock())
							EndIf
						endif
					endif
				EndIf
			EndIf

			//validação do vendedor selecionado
			oModelVen := STDGVenModel()
			If lRet .AND. Valtype(oModelVen) == "O"
				cCodVend := oModelVen:GetValue("SA3MASTER","A3_COD")
				aAreaSA3 := SA3->(GetArea())
				SA3->(DbSetOrder(1)) //A3_FILIAL+A3_COD
				SA3->(DbSeek(xFilial("SA3")+cCodVend))
				If SA3->(!Eof()) .and. !U_TPDVP23A(cCodVend)
					lRet := .F.
					Aviso( "Atenção!","O cargo (A3_CARGO) do vendedor "+SA3->A3_COD+"-"+AllTrim(SA3->A3_NOME)+" não está liberado para ser utilizado no PDV.", {"Ok"} )
				EndIf
				RestArea(aAreaSA3)
			EndIf

			if lRet .AND. lMvPswVend .AND. lMvVlIdent
				cCodVend := U_TPGetVend()
				if cCodVend <> cVenIdent
					Aviso( "Atenção!", "Este abastecimento é de outro frentista vendedor! Ação não permitida", {"Ok"} )
					lRet := .F.
				endif
			endif

		EndIf

	//valida inclusão que não é pelo GRID de abastecimentos: STISelAbast
	Else

		SB1->(DbSetOrder(1))
		If SB1->(DbSeek(xFilial("SB1") + cCodItem))
			MHZ->(DbSetOrder(3)) //MHZ_FILIAL+MHZ_CODPRO+MHZ_LOCAL
			If SB1->B1_MSBLQL == "1" //se o produto estiver bloqueado para venda
				lRet := .F.
				Aviso( "", "Produto bloqueado para venda!", {"Ok"} )

			ElseIf MHZ->(DbSeek(xFilial("MHZ")+SB1->B1_COD)) //verifica se é combustivel
				lRet := .F.
				Aviso( "", "Produto [combutível] sem permissão para venda via seleção de produto.", {"Ok"} )

			ElseIf !Empty(cTpProd) .and. !(SB1->B1_TIPO $ cTpProd)
				lRet := .F.
				Aviso( "", "O Produto '"+AllTrim(SB1->B1_COD)+" - "+AllTrim(SB1->B1_DESC)+"' está cadastrado com um Tipo de Produto "+;
					"('"+SB1->B1_TIPO+" - "+Alltrim(Posicione("SX5",1,xFilial("SX5")+"02"+SB1->B1_TIPO,"X5_DESCRI"))+"') que não está liberado para ser usado no PDV.", {"Ok"} )
			ElseIf U_URetPrec(SB1->B1_COD,,.F.) <= 0
				lRet := .F.
				Aviso( "", "Produto sem preço cadastrado na Tabela de Preço!", {"Ok"} )
			EndIf
		EndIf

	EndIf

	If lRet
		DbSelectArea("SA1")
		SA1->(dbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA

		If SA1->(DbSeek(xFilial("SA1")+cCliente+cLojaCli))

			If SA1->(ColumnPos("A1_XRESTGP")) > 0 .AND. !Empty(SA1->A1_XRESTGP)
				aGrpProd := StrTokArr(AllTrim(SA1->A1_XRESTGP),"/")
			EndIf

			If SA1->(ColumnPos("A1_XRESTPR")) > 0 .AND. !Empty(SA1->A1_XRESTPR)
				aProd := StrTokArr(AllTrim(SA1->A1_XRESTPR),"/")
			EndIf

			cNomeCli := SA1->A1_NOME

		EndIf
	EndIf

	//Mais de um produto e há pelo menos um tipo de restrição
	If lRet .AND. (oModelSL2:Length() >= 1) .And. (Len(aGrpProd) > 0 .Or. Len(aProd) > 0)

		DbSelectArea("SB1")
		SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD
		For nI := 1 To oModelSL2:Length()

			If lRet

				oModelSL2:GoLine(nI)

				If !oModelSL2:IsDeleted()

					//Restrição quanto ao Grupo de Produto
					If Len(aGrpProd) > 0

						If SB1->(DbSeek(xFilial("SB1")+oModelSL2:GetValue('L2_PRODUTO')))

							If aScan(aGrpProd,{|x| x == SB1->B1_GRUPO}) > 0

								If Len(aGrpRest) == 0
									AAdd(aGrpRest,SB1->B1_GRUPO)
								EndIf
							Else
								If Len(aGrpRest) == 0
									nContNGrp++
								EndIf
							EndIf
						EndIf
					EndIf

					//Restrição quanto ao Produto
					If Len(aProd) > 0

						If SB1->(DbSeek(xFilial("SB1")+oModelSL2:GetValue('L2_PRODUTO')))

							If aScan(aProd,{|x| AllTrim(x) == AllTrim(SB1->B1_COD)}) > 0

								If Len(aProdRest) == 0
									AAdd(aProdRest,AllTrim(SB1->B1_COD))
								EndIf
							Else
								If Len(aProdRest) == 0
									nContNProd++
								EndIf
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		Next nI

		If lRet

			//Restrição quanto ao Grupo de Produto
			If Len(aGrpProd) > 0 .And. Len(aGrpRest) > 0

				If SB1->(DbSeek(xFilial("SB1")+cCodItem))

					If aScan(aGrpProd,{|x| x == SB1->B1_GRUPO}) > 0

						If Len(aGrpRest) == 0

							AAdd(aGrpRest,SB1->B1_GRUPO)

							If nContNGrp > 0
								cDescGrp 	:= Posicione("SBM",1,xFilial("SBM")+SB1->B1_GRUPO,"BM_DESC")
								cDescProd	:= SB1->B1_DESC
								MsgInfo("Para o Cliente "+AllTrim(cNomeCli)+", há restrição de venda para o Grupo de Produto <"+AllTrim(cDescGrp)+">, referente ao produto <"+AllTrim(cDescProd)+">, faz-se necessário separar este produto em cupons fiscais distintos.","Atenção")
								lRet := .F.
							EndIf
						Else

							If aScan(aGrpRest,{|x| x == SB1->B1_GRUPO}) == 0

								cDescGrp 	:= Posicione("SBM",1,xFilial("SBM")+SB1->B1_GRUPO,"BM_DESC")
								cDescProd	:= SB1->B1_DESC
								MsgInfo("Para o Cliente "+AllTrim(cNomeCli)+", há restrição de venda para o Grupo de Produto <"+AllTrim(cDescGrp)+">, referente ao produto <"+AllTrim(cDescProd)+">, faz-se necessário separar este produto em cupons fiscais distintos.","Atenção")
								lRet := .F.
							EndIf
						EndIf
					Else
						If Len(aGrpRest) > 0
							cDescGrp 	:= Posicione("SBM",1,xFilial("SBM")+SB1->B1_GRUPO,"BM_DESC")
							cDescProd	:= SB1->B1_DESC
							MsgInfo("Para o Cliente "+AllTrim(cNomeCli)+", há restrição de venda para o Grupo de Produto <"+AllTrim(cDescGrp)+">, referente ao produto <"+AllTrim(cDescProd)+">, faz-se necessário separar este produto em cupons fiscais distintos.","Atenção")
							lRet := .F.
						Else
							nContNGrp++
						EndIf
					EndIf
				EndIf
			EndIf

			//Restrição quanto ao Produto
			If Len(aProd) > 0 .And. Len(aProdRest) > 0

				If SB1->(DbSeek(xFilial("SB1")+cCodItem))

					If aScan(aProd,{|x| AllTrim(x) == AllTrim(SB1->B1_COD)}) > 0

						If Len(aProdRest) == 0

							AAdd(aProdRest,AllTrim(SB1->B1_COD))

							If nContNProd > 0

								cDescProd	:= SB1->B1_DESC
								MsgInfo("Para o Cliente "+AllTrim(cNomeCli)+", há restrição de venda para o Produto <"+AllTrim(cDescProd)+">, faz-se necessário separar este produto em cupons fiscais distintos.","Atenção")
								lRet := .F.
							EndIf
						Else

							If aScan(aProdRest,{|x| x == AllTrim(SB1->B1_COD)}) == 0

								cDescProd	:= SB1->B1_DESC
								MsgInfo("Para o Cliente "+AllTrim(cNomeCli)+", há restrição de venda para o Produto <"+AllTrim(cDescProd)+">, faz-se necessário separar este produto em cupons fiscais distintos.","Atenção")
								lRet := .F.
							EndIf
						EndIf
					Else
						If Len(aProdRest) > 0
							cDescProd	:= SB1->B1_DESC
							MsgInfo("Para o Cliente "+AllTrim(cNomeCli)+", há restrição de venda para o Produto <"+AllTrim(cDescProd)+">, faz-se necessário separar este produto em cupons fiscais distintos.","Atenção")
							lRet := .F.
						Else
							nContNProd++
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf

	//Numero maximo de itens por venda -> MV_XQTMPDV (default 990)
	If lRet
		nItemLine := GetQtdItens(oModelSL2) + 1 //faço a soma com o item atual
		If nItemLine > nMaxItens
			LjGrvLog("L1_NUM: "+STDGPBasket('SL1','L1_NUM'),"Quantidade de itens lançados na venda ultrapassa o maximo de itens permitido no grid: " + AllTrim(Str(nItemLine)))
			STFMessage("ItemRegistered","STOP","Atingido numero maximo de itens por venda. Efetue nova venda.") //
			lRet := .F.
		EndIf
	EndIf

	RestArea(aAreaSA1)
	RestArea(aAreaSB1)

	If lRet
		AddBtnMsgNf()

		//SETA VENDEDOR LOGADO PARA PRODUTO
		//Se não está registrando a partir da importacao orçamento
		If lMvPswVend .AND. !IsInCallStack("STBImportSale")
			//se nao vem do grid de abastecimentos, ou vem mas está sem identfid
			If !IsInCallStack("STISelAbast") .OR. Empty(STDGPBasket("SL1","L1_VEND"))
				U_TpAtuVend()
			EndIf
		EndIf

		//Colocada a função abaixo para não bloquear grid de pagamentos
		STISetPayRO(-1)	//campos com escrita
	EndIf

Return lRet

//------------------------------------------------------------------------
// retorna a quantidade de itens na cesta
//------------------------------------------------------------------------
Static Function GetQtdItens(oModelSL2)

	Local nQtdItem := 0
	Local nI := 0

	For nI := 1 To oModelSL2:Length()
		If !oModelSL2:IsEmpty()
			oModelSL2:GoLine(nI)
			If !oModelSL2:IsDeleted()
				nQtdItem++
			EndIf
		EndIf
	Next nI

Return nQtdItem

//------------------------------------------------------------------------
// adiciona o botão Mensagem para Nota na tela de pagamentos
//------------------------------------------------------------------------
Static Function AddBtnMsgNf()

	Local oPnlBtn := STIGetDlg()
	Local nTop    	:= 10 	//Altura dos botoes
	Local nLeft		:= 10 	//Horizontal dos botoes
	Local nMargin 	:= 05	//Tamanho horizontal
	Local nWidth				//Lagura dos botoes
	Local nHeight				//Altura dos botoes
	Local nX			:= 1	//Posicao horizontal dos botoes
	Local nY			:= 2	//Posicao vertical dos botoes

	If oBtnMsgNF == Nil
		If oPnlBtn<>Nil
			nWidth := oPnlBtn:nWidth-35
			nWidth := (nWidth/2-nMargin*2)/3
			nHeight := 110
			nHeight := (nHeight/2-nMargin)/2

			@ nTop+(nX-1)*(nHeight+nMargin), nLeft+(nY-1)*(nWidth+nMargin) BUTTON oBtnMsgNF PROMPT "(Alt+O) &Observ. p/ Nota" SIZE nWidth,nHeight ACTION {|| ShowPnlMsgNf(oPnlBtn) } WHEN {|| iif(oPnlMsgNf==Nil,.T.,!oPnlMsgNf:lVisible .AND. lWhenBtnNF) } OF oPnlBtn PIXEL 
			oBtnMsgNF:SetCSS( POSCSS (GetClassName(oBtnMsgNF), CSS_BTN_NORMAL ))
			oBtnMsgNF:LCANGOTFOCUS := .F.

			//PAINEL PARA MENSAGEM
			oPnlMsgNf := tPanel():New(070, 000, "", oPnlBtn,,,,,, oPnlBtn:nWidth/2, (oPnlBtn:nHeight-140)/2)
			oPnlMsgNf:Hide()
			oPnlMsgNf:SetCSS( POSCSS (GetClassName(oPnlMsgNf), CSS_PANEL_CONTEXT ) )
			oPnlMsgNf:ReadClientCoors(.T.,.T.)

			nWidth := oPnlMsgNf:nWidth/2
			nHeight := oPnlMsgNf:nHeight/2

			@ 005, 012 SAY oSay1 PROMPT "Mensagem para Observações Nota" SIZE 200, 011 OF oPnlMsgNf COLORS 0, 16777215 PIXEL
			oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_BREADCUMB ))

			@ 030, 012 SAY oSay1 PROMPT "Mensagem/Observações" SIZE 100, 008 OF oPnlMsgNf COLORS 0, 16777215 PIXEL
			oSay1:SetCSS( POSCSS (GetClassName(oSay1), CSS_LABEL_FOCAL ))
			oMsgNf := TGet():New( 040, 012,{|u| iif(PCount()>0,cMsgNf:=u,cMsgNf)},oPnlMsgNf,nWidth-30, 013,"@N",{|| .T./*bValid*/ },,,,,,.T.,,,{|| .T. },,,,.F.,.F.,,"oMsgNota",,,,.T.,.F.)
			oMsgNf:SetCSS( POSCSS (GetClassName(oMsgNf), CSS_GET_NORMAL ))

			oBtn1 := TButton():New( nHeight-ALTURABTN-10.5,;
				nWidth-LARGBTN-10,;
				"&Confirmar"+CRLF+"(Alt+C)",;
				oPnlMsgNf	,;
				{|| oPnlMsgNf:Hide(), STIBtnActivate() },;
				LARGBTN,;
				ALTURABTN,;
				,,,.T.,;
				,,,{|| .T. })
			oBtn1:SetCSS( POSCSS (GetClassName(oBtn1), CSS_BTN_FOCAL ))

			oBtn2 := TButton():New( nHeight-ALTURABTN-10.5,;
				012,;
				"C&ancelar"+CRLF+"(Alt+A)",;
				oPnlMsgNf	,;
				{|| cMsgNf:=cBkpMsgNf, oPnlMsgNf:Hide(), STIBtnActivate() },;
				LARGBTN,;
				ALTURABTN,;
				,,,.T.,;
				,,,{|| .T. })
			oBtn2:SetCSS( POSCSS (GetClassName(oBtn2), CSS_BTN_ATIVO ))

		EndIf
	Else
		oBtnMsgNF:Show()
	EndIf

Return

User Function HideMsgNF()
	If oBtnMsgNF<>Nil
		oBtnMsgNF:Hide()
	EndIf
	cMsgNf := Space(150)
Return

User Function SetWBtnNF(_lWhenBtnNF)
	lWhenBtnNF := _lWhenBtnNF
	If oBtnMsgNF<>Nil
		oBtnMsgNF:Refresh()
	EndIf
Return

Static Function ShowPnlMsgNf(oPnlFormas)

	Local nWidth,nHeight

	cBkpMsgNf := cMsgNf

	STIBtnDeActivate()

	oPnlMsgNf:Show()
	oPnlMsgNf:Refresh()
	oMsgNf:SetFocus()

Return

User Function GetMsgNf()
Return cMsgNf
