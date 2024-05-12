#include 'protheus.ch'
#include 'parmtype.ch'

Static aKeysSav := {}

/*/{Protheus.doc} TPDVP002 (STMenEdt)
Este ponto de entrada é executado na inicialização da rotina TotvsPDV para edição dos itens no menu.
Possui como parâmetro de entrada, o array referente ao menu do TotvsPDV e retorna os itens de menu que serão exibidos na janela do TotvsPDV.

@author pablo
@since 16/10/2018
@version 1.0
@return aMenu

@type function
/*/
User Function TPDVP002()

	Local aMenu	:= PARAMIXB[1]
	Local aTemp := {}
	Local iX	:= 0
	Local lMvXGERENT := SuperGetMv("MV_XGERENT",,.F.)
	Local lOpenCash := STBOpenCash()
	Local cFPConv := SuperGetMv("TP_FPGCONV",,"")
	//Local lTplPosto 	:= GetNewPar("MV_LJPOSTO",.F.)
	Local lMVPLNoAb := SuperGetMV("MV_LJPLNAB",,.F.)

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return aClone(aMenu)
	EndIf

	//Remove os itens não utilizados no Totvs PDV
	For iX:=1 to Len(aMenu)

		If  !('Vale Troca'$aMenu[iX][02]) .and.;
				!('Vale Presente'$aMenu[iX][02]) .and.;
				!('Recebimento de Titulo'$aMenu[iX][02]) .and.;
				!('Estorno de titulos'$aMenu[iX][02]) .and.;
				!('Cancelar Recebimento'$aMenu[iX][02]) .and.;
				!('Correspondente bancario'$aMenu[iX][02]) .and.;
				!('Cadastro de Clientes'$aMenu[iX][02]) .and.;
				!('Recarga de celular'$aMenu[iX][02])

			//tratamento para filtrar caixas combo sangria e suprimento
			If lMvXGERENT .AND. ('SANGRIA' $ UPPER(aMenu[iX][02]) .OR. 'SUPRIMENTO' $ UPPER(aMenu[iX][02]))
				aMenu[iX][3] := "(U_HidePnlForm(), U_TPDVE014(1), "+aMenu[iX][3]+", U_TPDVE014(2),)"

				//rotinas que abrem tela, coloco ação de ocultar painel de formas de pagamento
			Elseif ('CPF' $ UPPER(aMenu[iX][02]) .OR. 'FRENTISTA' $ UPPER(aMenu[iX][02]) .OR. 'VENDEDOR' $ UPPER(aMenu[iX][02]) .OR. 'CANCELAR' $ UPPER(aMenu[iX][02]))
				aMenu[iX][3] := "(U_HidePnlForm(), "+aMenu[iX][3]+")"
				if 'FRENTISTA' $ UPPER(aMenu[iX][02]) .OR. 'VENDEDOR' $ UPPER(aMenu[iX][02])
					bBlocoAbast := &("{|| "+aMenu[iX][3]+" }")
					SetKey(K_CTRL_F8, bBlocoAbast)
					aMenu[iX][2] := Alltrim(aMenu[iX][2]) + " (CTRL+F8)"
				endif
			EndIf

			AAdd(aTemp , aMenu[iX])

		EndIf

	Next iX

	aMenu := aClone(aTemp)

	iX := Len(aMenu)

	AAdd( aMenu , { AllTrim(STR(++iX)), "Painel Posto Inteligente (F11)", "U_TPDVMAIN()", "M"} )
	SetKey(VK_F11, {|| U_TPDVMAIN() })

	if !lMVPLNoAb
		AAdd( aMenu , { AllTrim(STR(++iX)), "Aferição de Bico", "U_TPDVA003()", ""} ) //"Aferição de Bico"
		AAdd( aMenu , { AllTrim(STR(++iX)), "Manutenção de Bomba", "U_TPDVA004()", ""} ) //"Manuteção de Bomba"
		AAdd( aMenu , { AllTrim(STR(++iX)), "Rel. Encerrantes", "U_TPDVR004()", "M"} ) //"Relatorio de Leitura de Encerrantes"
	endif

	AAdd( aMenu , { AllTrim(STR(++iX)), "Atualizar Cliente/Grupo (F9)", "U_TPDVE011()", "M"} )
	SetKey(VK_F9, {|| U_TPDVE011() })

	//ativa impressao e gravaçao de orçamento na central
	If SuperGetMv("TP_ACTORC",,.F.)
		AAdd( aMenu , { AllTrim(STR(++iX)), "Orçamentos", "U_TPDVA001()", "M"} )
	EndIf

	//ser controle de senha por vendedor habilitado
	If SuperGetMv("TP_PSWVEND",,.F.)
		AAdd( aMenu , { AllTrim(STR(++iX)), "Bloquear PDV (SHIFT+F1)", "U_TPDVE013()", "M"} )
		SetKey(K_SH_F1, {|| U_TPDVE013() })
	EndIf

	AAdd( aMenu , { AllTrim(STR(++iX)), "Ultimo CPF/CNPJ (SHIFT+F2)", "U_TPDVP08A()", "M"} )
	SetKey(K_SH_F2, {|| U_TPDVP08A() }) //Atalho (SHIFT+F2) para carregar cgc, nome, endereço, placa, odomentro

	AAdd( aMenu , { AllTrim(STR(++iX)), "Limpar Tela (SHIFT+F3)", "U_TPDVP02A()", "M"} )
	SetKey(K_SH_F3, {|| U_TPDVP02A() }) //Limpar Tela (SHIFT+F3)

	if SuperGetMv("TP_PSWVEND",,.F.)
		AAdd( aMenu , { AllTrim(STR(++iX)), "Rel.Caixa x Vendedor (SHIFT+F8)", "U_TPDVP02C()", "M"} )
		SetKey(K_SH_F8, {|| U_TPDVP02C() })
	endif

	AAdd( aMenu , { AllTrim(STR(++iX)), "Consulta Limite Credito (SHIFT+F9)", "U_TPDVA013()", "M"} )
	SetKey(K_SH_F9, {|| U_TPDVA013() })

	//AAdd( aMenu , { AllTrim(STR(++iX)), "Epson TM-T20X", "U_UIMPT20X()", "M"} ) //TODO: TEMPORARIO para teste de impressora Epson TM-T20X
	//AAdd( aMenu , { AllTrim(STR(++iX)), "Lista Cheque Troco", "U_TPDVP02B()", "M"} )

	//AAdd( aMenu , { AllTrim(STR(++iX)), "Teste de Impressão de Cheque 1", "U_TPDVE07C()", "M"} ) //TODO: TEMPORARIO para teste de impressora de cheque
	//AAdd( aMenu , { AllTrim(STR(++iX)), "Teste de Impressão de Cheque 2", "U_ULOJG064()", "M"} ) //TODO: TEMPORARIO para teste de impressora de cheque

	//tratamento para filtrar caixas combo abertura caixa
	If lMvXGERENT .AND. !lOpenCash
		U_TPDVE014(1)
	EndIf

//solicitação NUTRIZA: disponibilizar status de CONTINGÊNCIA no PDV
//chamado: POSTO-56 - Erro no Cancelamento de NFC-e
	If SuperGetMV("TP_STATTSS",,.F.) //Habilita parametros e status do TSS (defalt .F.)
		cBkpFunNam := FunName()
		SetFunName("LOJA701")
		AAdd( aMenu , { AllTrim(STR(++iX)), "Parâmetros - NFC-e", "LjNFCePar()", "M"} ) //"SpedNFePar('65')"
		SetFunName(cBkpFunNam)
		//AAdd( aMenu , { AllTrim(STR(++iX)), "Parâmetros - NF-e", "SpedNFePar()", "M"} )
	EndIf

	//tratamento para abasteciemnto preso "em orçamento" na central
	//POSTO-741 - Abastecimentos retornam pra tela - Sereia - 17/02/23
	If FindFunction("U_UPABASOR") .AND. !lMVPLNoAb
		MsAguarde({|| U_UPABASOR() },"Aguarde...","Verificando abastecimentos presos....",.T.)
	EndIf

	//Tratamento para usar PX/PD como pagamento customizado (convenio)
	if "PX" $ cFPConv .OR. "PD" $ cFPConv
		U_TPDVE018()
	endif

	//Tratamento para ver se alguma venda ta com L1_SITUA = 00 e L1_FORCADA = S (para eventual queda sistema entre a gravação da venda e o PE STFinishSale)
	//Enquanto se tem o flag L1_FORCADA preenchido, aborta a subida da venda (esse campo padrão não usa no TotvsPDV)
	//Regra depende do ponto de entrada STDUPSL1.
	VerUpSL1()

Return aClone(aMenu)

//-------------------------------------------------------------------
/*/{Protheus.doc} TPDVP02A
Cancela venda quando configurado com nfc-e e esta em andamento (SHIFT+F3)

@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TPDVP02A()

	Local cDoc, oTelaPDV, nConfCx
	Local lIsProgress
	Local lMvPswVend := SuperGetMv("TP_PSWVEND",,.F.)
	Local cCodVend := ""
	Local lRet := .T.

	//se caixa está aberto
	If STBOpenCash()

		//verifico se está na tela de conferencia de caixa do pdv
		oTelaPDV := STIGetObjTela()
		nConfCx := aScan(oTelaPDV:oowner:acontrols, {|x| iif(valtype(x)=="O", x:cCaption == "Conferência de Caixa", .f.) })

		If nConfCx == 0

			lIsProgress := STBCSIsProgressSale()

			If STIGetTotal() == 0
				/*Cancela venda quando configurado com nfc-e e esta em andamento*/
				cDoc := STDGPBasket("SL1","L1_DOC")
				If STWCancelSale(.T.,,,cDoc, "L1_NUM",,)

					If lIsProgress
						STIGridCupRefresh()
					EndIf
					STIRegItemInterface()

					// Limpa variavel de verificação de regra de desconto por item
					STBLimpRegra(.F.)

					//posiciono no vendedor logado
					If lMvPswVend .and. !Empty(cCodVend := U_TPGetVend()) .and. cCodVend <> GetMV("MV_VENDPAD")
						SA3->(DbSetOrder(1))
						SA3->(DbSeek(xFilial("SA3") + cCodVend ))
					EndIf

				EndIf
			Else
				STFMessage( "TPDVP02A","STOP", "Limpar tela só permitido se não informou formas de pagamento.")
				STFShowMessage("TPDVP02A")
				lRet := .F.
			EndIf

		EndIf

	EndIf

Return lRet

/*/{Protheus.doc} User Function UKeyCtr
Salva e Restaura Teclas de Atalho
@type  Function
@author Danilo
@since 19/11/2020
@version 1
/*/
User Function UKeyCtr(lRestaura, lClear)

	Local nX
	Default lRestaura := .F.
	Default lClear := .F.

	if lRestaura
		LjGrvLog("UKeyCtr","Ação","Restaura")

		for nX := 1 to len(aKeysSav)
			SetKey(aKeysSav[nX][1], aKeysSav[nX][2])
		next nX
	else
		if empty(aKeysSav)
			LjGrvLog("UKeyCtr","Ação","Faz Backup no aKeysSav")
			aadd(aKeysSav, {VK_F1,SetKey(VK_F1)})
			aadd(aKeysSav, {VK_F2,SetKey(VK_F2)})
			aadd(aKeysSav, {VK_F3,SetKey(VK_F3)})
			aadd(aKeysSav, {VK_F4,SetKey(VK_F4)})
			aadd(aKeysSav, {VK_F5,SetKey(VK_F5)})
			aadd(aKeysSav, {VK_F6,SetKey(VK_F6)})
			aadd(aKeysSav, {VK_F7,SetKey(VK_F7)})
			aadd(aKeysSav, {VK_F8,SetKey(VK_F8)})
			aadd(aKeysSav, {VK_F9,SetKey(VK_F9)})
			aadd(aKeysSav, {VK_F10,SetKey(VK_F10)})
			aadd(aKeysSav, {VK_F11,SetKey(VK_F11)})
			aadd(aKeysSav, {VK_F12,SetKey(VK_F12)})
			aadd(aKeysSav, {K_SH_F1,SetKey(K_SH_F1)})
			aadd(aKeysSav, {K_SH_F2,SetKey(K_SH_F2)})
			aadd(aKeysSav, {K_SH_F3,SetKey(K_SH_F3)})
			aadd(aKeysSav, {K_SH_F8,SetKey(K_SH_F8)})
			aadd(aKeysSav, {K_SH_F9,SetKey(K_SH_F9)})
			aadd(aKeysSav, {K_CTRL_F8,SetKey(K_CTRL_F8)})
		endif

		LjGrvLog("UKeyCtr","Ação","Limpa")
		SetKey(VK_F1, {|| })
		SetKey(VK_F2, {|| })
		SetKey(VK_F3, {|| })
		SetKey(VK_F4, {|| })
		SetKey(VK_F5, {|| })
		SetKey(VK_F6, {|| })
		SetKey(VK_F7, {|| })
		SetKey(VK_F8, {|| })
		SetKey(VK_F9, {|| })
		SetKey(VK_F10, {|| })
		SetKey(VK_F11, {|| })
		SetKey(VK_F12, {|| })
		SetKey(K_SH_F1, {|| })
		SetKey(K_SH_F2, {|| })
		SetKey(K_SH_F3, {|| })
		SetKey(K_SH_F8, {|| })
		SetKey(K_SH_F9, {|| })
		SetKey(K_CTRL_F8, {|| })
	endif

	if lClear
		LjGrvLog("UKeyCtr","Ação","Zera aKeysSav")
		aKeysSav := {}
	endif

	SalvaProc("UKeyCtr")

Return

/*/{Protheus.doc} SalvaProc
Função que salva as chamadas dos ProcNames e escrever no LOG

@author Totvs GO
@since 15/05/2020
@version 1.0
/*/
Static Function SalvaProc(cRotCall)
	Local aArea := GetArea()
	Local nCont := 1
	Local cPilha := ""

	cPilha := 'FunName: '+FunName()+CRLF
	//Enquanto houver procname que não estão em branco
	While !Empty(ProcName(nCont))
		//Escrevendo o número do procname e a descrição
		cPilha += 'ProcName > '+StrZero(nCont, 6)+' - '+ProcName(nCont)+CRLF
		nCont++
	EndDo

	//Grava o log da pilha de funções
	LjGrvLog(cRotCall,"Pilha de Chamadas",cPilha)

	RestArea(aArea)
Return

/*/{Protheus.doc} TPDVP02B
Menu para impressão da lista de cheque troco do PDV

@type function
@version 1
@author Totvs GO
@since 05/05/2021
/*/
User Function TPDVP02B()
	Local aItensCh := {}
	//Prepara para consultar cheques trocos que serão transferidos para usuario PDV.
	aItensCh := U_TPDVP16A()
	If Len(aItensCh)>0
		U_TRETR013(3,aItensCh) //impressao dos cheques transfereridos
	Else
		STFMessage("TPDVP02B", "STOP", "Nenhum cheque troco associado ao PDV "+cPdv+".")
		STFShowMessage("TPDVP02B")
	EndIf
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} TPDVP02C
Posiciona na SLW e chama a impressão do Rel.Caixa x Vendedor
/*/
//-------------------------------------------------------------------
User Function TPDVP02C( )

	Local aArea			:= GetArea()						//Guarda area
	Local aStation		:= STBInfoEst(	1, .T. ) 			//Informacoes da estacao  // [1]-CAIXA [2]-ESTACAO [3]-SERIE [4]-PDV
	Local lRet			:= .T.								//Retorno
	Local cChave		:= ""								//Chave de Pesquisa
	Local cNumMov		:= AllTrim(STDNumMov())				//Numero do Movimento
	Local lConfCaixa 	:= SuperGetMV( "MV_LJCONFF",,.F. )  //Parametro da conferencia de caixa
	Local nIndice		:= 1								//Numero do indice

	If !lConfCaixa
		//Pesquisar o proximo movimento em aberto que deve ser finalizado
		cChave 	:= xFilial("SLW") + aStation[4] + aStation[1]
		nIndice 	:= 1 //LW_FILIAL+LW_PDV+LW_OPERADO+DTOS(LW_DTABERT)+LW_NUMMOV
	Else
		cChave 	:= STDUtMovAb(1,aStation[1],aStation[4],aStation[2],cNumMov,.T.)
		nIndice 	:= 3 //LW_FILIAL+LW_PDV+LW_OPERADO+DTOS(LW_DTABERT)+LW_ESTACAO+LW_NUMMOV
	EndIf

	If !Empty(cNumMov)
		cLastNumMov := cNumMov
	EndIf

	DbSelectArea("SLW")
	DbSetOrder(nIndice)
	If DbSeek( cChave )

		If !lConfCaixa
			While !SLW->(Eof()) .AND. ( SLW->(LW_FILIAL + LW_PDV + LW_OPERADO) == cChave ) .AND. ( DtoC(SLW->LW_DTFECHA) <> "  /  /  " )
				SLW->(dbSkip())
			EndDo
		EndIf

		If !SLW->(Eof())
			U_TRA028RI() //Rel.Caixa x Vendedor
		EndIf

	EndIf

	RestArea(aArea)

Return lRet

//Tratamento para ver se alguma venda ta com L1_SITUA = 00 e L1_FORCADA = S (para eventual queda sistema entre a gravação da venda e o PE STFinishSale)
//Enquanto se tem o flag L1_FORCADA preenchido, aborta a subida da venda (esse campo padrão não usa no TotvsPDV)
//Regra depende do ponto de entrada STDUPSL1.
Static Function VerUpSL1()

	Local aArea := GetArea()
	Local aAreaSL1 := SL1->(GetArea())
	
	SL1->( DbSetOrder(9) )	//L1_FILIAL+L1_SITUA+L1_PDV+L1_DOC   
	SL1->( DbSeek(xFilial("SL1")+"00") )
	While SL1->(!Eof()) .AND. SL1->L1_FILIAL + SL1->L1_SITUA == xFilial("SL1")+"00"
		if SL1->L1_FORCADA == "S"
			//limpo pois aqui trato queda de sistema, então sobe a venda do jeito que ficou
			RecLock("SL1", .F.)
				SL1->L1_FORCADA := " "
			SL1->(MsUnLock())
		endif

		SL1->(DbSkip())
	enddo

	RestArea(aAreaSL1)
	RestArea(aArea)

Return
