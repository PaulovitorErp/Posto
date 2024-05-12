#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} TRETE029
Rotina de geração de Cheque Avulso

	A elaboração de cheques avulsos é realizada quando há a necessidade de pagamento
	como simples saída de caixa, não havEndo vínculo algum com títulos já existentes.

	A configuração do parâmetro MV_LIBCHEQ, conteúdo configurado com "N" permite
	controlar a emissão de cheques avulsos pela natureza cadastrada.

@author Rafael Brito
@since 02/05/2019
@version 1.0

@return booleano, Se foi processado com sucesso ou não
@param nRecUF2, numeric, recno do Cheque Troco a ser gerado cheque avulso

@description
Gera Cheque Avulso, quando o cheque for selecionado na tela do loja posto


@type function
/*/

User Function TRETE029(nRecUF2)

	Local aArea    := GetArea()
	Local aAreaSEF := SEF->(GetArea())
	Local aAreaUF2 := UF2->(GetARea())
	Local lRet     := .T.
	Local aAutoCab := {}
	Local nOpc     := 3 //Cheque Avulso
	Local cLIBCHEQ := ""
	Local nRegSEF
	Local lContinua := .F.
//Local cBK_LIBCHEQ := ""
	Local nRecEFAux := 0
	Local cCheqAux := ""
	Private lMsHelpAuto := .T. // para nao mostrar os erro na tela
	Private lMsErroAuto := .F. // inicializa como falso, se voltar verdadeiro e' que deu erro

//Conout("TRETE029 - Inicio - UF2 Recno: " + cvaltochar(nRecUF2))

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ guarda o bakcup do conteudo do parametro    					   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cLIBCHEQ := SuperGetMV( "MV_LIBCHEQ" , .T./*lHelp*/, "S" )
//Conout("TRETE029 - UF2 Recno: " + cvaltochar(nRecUF2) + " - MV_LIBCHEQ Antes de mudar: " + cBK_LIBCHEQ)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Força a liberação automatica dos cheque avulso!!!                                                              ³
//³ "MV_LIBCHEQ" - Opcao para liberacao de saldo bancario quando da geracao de cheques antes da baixa.             ³
//³ Para utilização do Cheque Troco, o conteudo do parametro eh forçado a ficar igual a "S" - Liberação automatica.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//If cBK_LIBCHEQ = "N"
//	PutMv("MV_LIBCHEQ","S")
//	cLIBCHEQ := GETMV("MV_LIBCHEQ")
//	//Conout("TRETE029 - UF2 Recno: " + cvaltochar(nRecUF2) + " - MV_LIBCHEQ Depois de mudar: " + cLIBCHEQ)
//Else
//	cLIBCHEQ := cBK_LIBCHEQ
//EndIf

	DbSelectArea("UF2")
	UF2->(DbGoTo(nRecUF2))
	If UF2->(!Eof()) .and. UF2->UF2_VALOR > 0

		//-- valida se já gerou financeiro REQUISIÇÃO / COMPENSAÇÃO / VENDA
		lContinua := .F.
		If !Empty(UF2->UF2_CODBAR) .and. ReqTemFin(UF2->UF2_CODBAR) //se REQUISIÇÃO
			lContinua := .T.
		ElseIf UF2->UF2_SERIE $ SuperGetMV("MV_XPFXCOM", .T., "CMP") //se COMPENSAÇÃO
			UC0->(DbSetOrder(1))
			If UC0->(DbSeek(xFilial("UC0")+UF2->UF2_DOC)) .and. UC0->UC0_GERFIN == "S"
				lContinua := .T.
			EndIf
		Else //se VENDA FISCAL
			SL1->(DbSetOrder(2)) //L1_FILIAL+L1_SERIE+L1_DOC+L1_PDV
			If SL1->(DbSeek(xFilial("SL1")+UF2->UF2_SERIE+UF2->UF2_DOC))
				While SL1->(!Eof()) .AND. SL1->L1_FILIAL+SL1->L1_SERIE+SL1->L1_DOC == xFilial("SL1")+UF2->UF2_SERIE+UF2->UF2_DOC
					If SL1->L1_SITUA == "OK" //--só vai gerar financeiro se gravabatch ja processou financeiro
						lContinua := .T.
						Exit //sai do While
					EndIf
					SL1->(DbSkip())
				EndDo
			EndIf
		EndIf

		If lContinua //-- apos validar se gerou financeiro, processa o cheque avulso

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ajusto a database do sistema para a data do movimento.³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			dDataBase := UF2->UF2_DATAMO

			cNaturez := UF2->UF2_NATURE
			If Empty(cNaturez)
				cNaturez := SuperGetMV("MV_XNATCHA", .T./*lHelp*/, "CHEQUE"/*cPadrao*/)
			EndIf

			aAutoCab := { { "AUTBANCO"   , UF2->UF2_BANCO, Nil},;
				{ "AUTAGENCIA" , UF2->UF2_AGENCI, Nil},;
				{ "AUTCONTA"   , UF2->UF2_CONTA, Nil},;
				{ "AUTCHEQUE"  , UF2->UF2_NUM, Nil},;
				{ "AUTVALOR"   , UF2->UF2_VALOR, Nil},;
				{ "AUTNATUREZA", cNaturez, Nil},;
				{ "AUTBENEF"   , UF2->UF2_BENEF, Nil} }

			SEF->(DbSetOrder(1)) //EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM
			If !SEF->(DbSeek(xFilial("SEF")+UF2->UF2_BANCO+UF2->UF2_AGENCI+UF2->UF2_CONTA+UF2->UF2_NUM))

				FinA390(,aAutoCab,nOpc) //execauto rotina de cheques avulsos

			ElseIf SEF->EF_CART == 'R' //se o SEF que encontrou for carteira contas a receber.. posso incluir CHT (a pagar)

				nRecEFAux := SEF->(Recno()) //guardo recno dele
				cCheqAux  := SEF->EF_NUM
				SEF->(RecLock("SEF",.F.)) //pego o cheque e altero chave dele para nao dar erro no execauto
				SEF->EF_NUM := "XXXXXX"
				SEF->(MsUnlock())

				FinA390(,aAutoCab,nOpc) //execauto rotina de cheques avulsos

			/*
				FINA390(nPosArotina,xAutoCab,nOpcAuto)

				Parâmetros:

				nPosArotina
				Utilizado para indicar a operação a ser executada. Utilizada apenas pela chamada da rotina padrão pelo menu. Enviar NIL ou 0 (zero)

				aAutoCab
				Utilizado para enviar dados referentes ao processo, como:
				- Banco
				- Agencia
				- Conta
				- Numero do Cheque
				- Valor do cheque
				- Natureza
				- Beneficiario
				- Historico (Somente para Cheque sobre titulo)
				- Vencimento de (Somente para Cheque sobre titulo)
				- Vencimento ate (Somente para Cheque sobre titulo)
				- Fornecedor (Somente para Cheque sobre titulo)

				nOpcAuto
				Processo que se deseja realizar:
				2 = Cheque Sobre titulo
				3 = Cheque Avulso

				cAutoFil
				Expressão ADVPL para filtro de seleção dos titulos geradores da liquidação (a serem liquidados).
			*/

			ElseIf AllTrim(cLIBCHEQ) == "S" .and. SEF->EF_LIBER == "S" //cheque ja gerado e liberado anteriormente
				lRet := .F.

				//Atualiza status ao confirmar que deseja imprimir Cheque Troco
				//Conout("Chave do Cheque: <EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM>" + SEF->(EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM))
				SEF->(RecLock("SEF",.F.))
				SEF->EF_IMPRESS := "S"
				SEF->(MsUnlock())
			EndIf

			If lMsErroAuto
				//MostraErro() //apresenta mensagem de erro "MostraErro()"
				If !IsBlind()
					MostraErro()
				Else
					cErroExec := MostraErro("\temp")
					//Conout(" ============ ERRO - Geração de Cheque Avulso, quando o cheque for selecionado na tela do loja posto: FINA390(nPosArotina,xAutoCab,nOpcAuto)  =============")
					//Conout(cErroExec)
					cErroExec := ""
				EndIf
				lRet := .F.
			Else

				If AllTrim(cLIBCHEQ) == "S" .and. SEF->EF_LIBER == "N" //nao ocorre liberação automatica
					fA190Lib() //FINA190 -> fA190Lib "Liberacao do cheque -> atualiza o saldo bancario SE5"
				EndIf

				//atualiza os dados do cupom no Cheque Avulso
				RecLock("SEF",.F.)
				SEF->EF_IMPRESS := "S"
				SEF->EF_NUMNOTA := UF2->UF2_DOC
				SEF->EF_SERIE	:= UF2->UF2_SERIE
				SEF->EF_HIST	:= "CHEQUE TROCO NO PDV"
				SEF->EF_CLIENTE := UF2->UF2_CLIENT
				SEF->EF_LOJACLI := UF2->UF2_LOJACL
				//Incluido por André R. Barrero - Para alimentar com o Nr. do PDV para mostrar no Browse
				SEF->EF_XPDV	:= UF2->UF2_PDV
				If SEF->(FieldPos("EF_XCODBAR"))>0
					SEF->EF_XCODBAR := UF2->UF2_CODBAR
				EndIf
				SEF->(MsUnLock())

				//atualiza o complemento dos dados na SE5
				//se foi liberado logo na inclusao da SEF, nao passa pelo PE F190SE5
				If AllTrim(cLIBCHEQ) == "S" .and. SEF->EF_LIBER == "S" 
					nRegSEF := SEF->(Recno())
					U_TRETE29B(nRegSEF) 
					SEF->(DbGoTo(nRegSEF))
				endif

				If AllTrim(cLIBCHEQ) == "S" .and. SEF->EF_LIBER <> "S"
					lRet := .F.
				Else
					lRet := .T.
				EndIf

			EndIf

			//--volto Num cheque recebido
			If nRecEFAux > 0
				SEF->(DBGoTo(nRecEFAux))
				SEF->(RecLock("SEF",.F.)) //Volto chave do cheque recebido caso tenha alterado
				SEF->EF_NUM := cCheqAux
				SEF->(MsUnlock())
			EndIf

			//-- ajusta a saida de troco REQUISIÇÃO / COMPENSAÇÃO / VENDA
			If lRet
				If !Empty(UF2->UF2_CODBAR) .and. ReqTemFin(UF2->UF2_CODBAR) //se REQUISIÇÃO
					U_TRETE29D(UF2->UF2_CODBAR)
				ElseIf UF2->UF2_SERIE $ SuperGetMV("MV_XPFXCOM", .T., "CMP") //se COMPENSAÇÃO
					//-- não é necessário, pois o JOB da compensação so gera financeiro para parte do dinheiro
				Else //se VENDA FISCAL
					U_TRETE29F(UF2->UF2_VALOR) //apenas valor do Cheque Troco
				EndIf
			EndIf

		Else
			If !IsBlind()
				MsgAlert("Não foi possível gerar o financeiro do cheque troco. Motivo: a requisição " + UF2->UF2_CODBAR + " não gerou financeiro.","Atenção")
				lRet := .F.
			EndIf
		EndIf

		If lContinua .AND. lRet //-- se tudo OK, atualiza o flag para FINANCEIRO GERADO
			RecLock("UF2")
			UF2->UF2_XGERAF := 'G'
			UF2->(MsUnlock())
		EndIf

	EndIf

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Volta o bakcup do conteudo do parametro.³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//Conout("TRETE029 - UF2 Recno: " + cvaltochar(nRecUF2) + " - MV_LIBCHEQ Voltando valor anterior: " + cBK_LIBCHEQ)
//If cBK_LIBCHEQ = "N"
//	PutMv("MV_LIBCHEQ",cBK_LIBCHEQ)
//	cLIBCHEQ := GetMV( "MV_LIBCHEQ")
//	//Conout("TRETE029 - UF2 Recno: " + cvaltochar(nRecUF2) + " - MV_LIBCHEQ Depois de voltar: " + cLIBCHEQ)
//EndIf

//Conout("TRETE029 - Fim - UF2 Recno: " + cvaltochar(nRecUF2))

	RestArea(aAreaUF2)
	RestArea(aAreaSEF)
	RestArea(aArea)

Return (lRet)

//--------------------------------------------------------------------
// Retorna se requisição tem financeiro (credito) ja baixado e usado
//--------------------------------------------------------------------
Static Function ReqTemFin(cCodbar)

	Local aArea := GetArea()
	Local aAreaSE1 := SE1->(GetArea())
	Local aAreaU56 := U56->(GetArea())
	Local aAreaU57 := U57->(GetArea())
	Local cPfRqSaq := AllTrim(SuperGetMV("MV_XPRFXRS", .T., "RPS")) // Prefixo de Titulo de Requisicoes de Saque
	Local lRet  := .F.
	Local cPulaLinha := chr(13)+chr(10)

	U57->(DbSetOrder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL
	If U57->(DbSeek(xFilial("U57")+cCodbar))

		DbSelectArea("U56")
		U56->(DbSetOrder(1)) //U56_FILIAL+U56_PREFIX+U56_CODIGO
		U56->(DbSeek(U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO)))

		//DbSelectArea("SE1")
		//SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

		cQry := "select SE1.R_E_C_N_O_ AS SE1RECNO" + cPulaLinha
		cQry += " from " + RetSqlName("SE1") + " SE1" + cPulaLinha
		cQry += " where SE1.D_E_L_E_T_ <> '*'" + cPulaLinha
		cQry += " and SE1.E1_FILIAL = '" + xFilial("SE1") + "'" + cPulaLinha
		If U56->U56_TIPO == '1' //PRE PAGA
			cQry += " and E1_PREFIXO = '" + "RPR" + "'" + cPulaLinha
			cQry += " and E1_TIPO IN ('RA ','NCC')" + cPulaLinha //pode ter NCC, devido a transferencia de titulos
		ElseIf U56->U56_TIPO == '2' //POS PAGA
			cQry += " and E1_PREFIXO = '" + IIF(U57->U57_TUSO=="S",cPfRqSaq,"RPC") + "'" + cPulaLinha
			cQry += " and E1_TIPO IN ('NCC')" + cPulaLinha
		EndIf
		cQry += " and SE1.E1_XCODBAR = '" + AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL) + "'" + cPulaLinha
		cQry += " and SE1.E1_BAIXA <> '' and SE1.E1_SALDO <= 0" + cPulaLinha

		If Select("QRYSE1") > 0
			QRYSE1->(DbCloseArea())
		EndIf

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYSE1" // Cria uma nova area com o resultado do query

		//QRYSE1->(dbEval({|| nCount++}))
		QRYSE1->(DbGoTop())

		If QRYSE1->(!Eof())
			lRet := .T.
		EndIf

		If Select("QRYSE1") > 0
			QRYSE1->(DbCloseArea())
		EndIf

	EndIf

	RestArea(aAreaSE1)
	RestArea(aAreaU57)
	RestArea(aAreaU56)
	RestArea(aArea)
Return lRet

//--------------------------------------------
// Ajusta os dados do cheque troco OFF-LINE
//--------------------------------------------
User Function TRETE29A(nRecUF2, nValor, cDoc, cSerie, cCodBar, cCliente, cLojaCli, cNaturez)

	Local lRet := .T.
	Local lChTrOp := SuperGetMV("MV_XCHTROP",,.F.) //Controle de Cheque Troco por Operador (default .F.)

	If nValor > 0

		DbSelectArea("UF2")
		UF2->(DbGoTo(nRecUF2))
		If UF2->(!Eof())
			RecLock("UF2")
			UF2->UF2_VALOR 	:= nValor
			UF2->UF2_STATUS := "2" //cheque gerado na SEF e liberado (SE5)
			UF2->UF2_DOC   	:= cDoc
			UF2->UF2_SERIE 	:= cSerie
			UF2->UF2_CODBAR	:= cCodBar
			UF2->UF2_CLIENT := cCliente
			UF2->UF2_LOJACL	:= cLojaCli
			UF2->UF2_NATURE	:= cNaturez
			UF2->UF2_XGERAF := "P"
			UF2->UF2_XOPERA	:= xNumCaixa()
			UF2->UF2_XPDV	:= LJGetStation("LG_PDV")
			If lChTrOp  // Felipe 23/01/2023 - Chamado POSTO-327
				UF2->UF2_PDV	:= LJGetStation("LG_PDV")
			EndIf
			UF2->UF2_XESTAC	:= LJGetStation("LG_CODIGO")
			UF2->UF2_XNUMMO	:= AllTrim(LjNumMov())
			UF2->UF2_XHORA	:= Time()
			UF2->UF2_DATAMO	:= dDataBase
			UF2->(MsUnlock())

			U_UREPLICA("UF2", 1, UF2->(UF2_FILIAL+UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_SEQUEN+UF2_NUM), "A")

		EndIf

	EndIf

Return(lRet)

//-----------------------------------------------
// Faz o complemente dos dados do cheque na SE5
//-----------------------------------------------
User Function TRETE29B(nRegSEF)

	Local aArea		:= GetArea()
	Local aAreaSE5	:= SE5->(GetArea())
	Local aAreaSEF  := SEF->(GetArea())
	Local aAreaUF2  := UF2->(GetArea())
	Local cChave 	:= ""
	Default nRegSEF := 0

	dbSelectArea( "SEF" )
	SEF->(dbSetOrder(1)) //EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM

	SEF->(dbGoto(nRegSEF))
	If SEF->(!Eof())
		cChave := SEF->(EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM)
	EndIf

	While SEF->(!Eof()) .and. cChave == SEF->(EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM)
		If SEF->EF_LIBER == "S" //ocorreu liberação
			///ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
			//= Atualiza complemento da movimentação bancaria =
			//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
			dbSelectArea( "SE5" )
			cFilialSe5 := xFilial("SE5")
			If SEF->(FieldPos("EF_FILORIG")) > 0
				If !Empty(SEF->EF_FILORIG)
					cFilialSe5 := SEF->EF_FILORIG
				EndIf
			EndIf
			SE5->(dbSetOrder(11))
			If SE5->( dbSeek(xFilial("SE5",cFilialSe5)+SEF->EF_BANCO+SEF->EF_AGENCIA+SEF->EF_CONTA+SEF->EF_NUM,.T.) )
				While ( SE5->(!Eof()) .And.	SE5->E5_BANCO   == SEF->EF_BANCO   .And. ;
						SE5->E5_AGENCIA == SEF->EF_AGENCIA .And. ;
						SE5->E5_CONTA   == SEF->EF_CONTA .And. ;
						ALLTRIM(SE5->E5_NUMCHEQ) == ALLTRIM(SEF->EF_NUM) )

					///ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒø
					//= So considera quando for cheque da baixa ou da mov bancaria=
					//¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ
					If ( Alltrim(SE5->E5_NUMCHEQ) == Alltrim(SEF->EF_NUM) .And.;
							!(SE5->E5_TIPODOC $ "VL/BA/CM/MT/DC/JR/TL/V2/D2/V2/IS/ES/EC") .And.;
							(!EMPTY(SE5->E5_TIPODOC) .or. SE5->E5_MOEDA $ "C1/C2/C3/C4/C5/CH  ") )

						If Empty(SE5->E5_PREFIXO) //If SE5->E5_SEQ == SEF->EF_SEQUENC
							RecLock( "SE5" )
							SE5->E5_PREFIXO := SEF->EF_SERIE
							SE5->E5_NUMERO  := SEF->EF_NUMNOTA
							//SE5->E5_DOCUMEN := SEF->EF_SERIE + "/" + SEF->EF_NUMNOTA
							SE5->E5_CLIFOR	:= SEF->EF_CLIENTE
							SE5->E5_LOJA 	:= SEF->EF_LOJACLI
							SE5->E5_HISTOR 	:= SEF->EF_HIST
							//Incluido por André R. Barrero - 16/11/2015
							SE5->E5_XPDV 	:= SEF->EF_XPDV
							SE5->( MsUnlock() )
						EndIf
					EndIf
					SE5->(dbSkip())
				EndDo
			EndIf
		EndIf
		SEF->(dbSkip())
	EndDo

	RestArea(aAreaSEF)
	RestArea(aAreaSE5)
	RestArea(aArea)
Return

//-------------------------------------------------------
// Estorna o financeiro do cheque troco -> EstFinCHT
//-------------------------------------------------------
User Function TRETE29C(nRecUF2,lReplica)

	Local aArea := UF2->(GetArea())
	Local lRet := .F.
	Local nRecSEF := 0
	//Conout(" >> TRETE029 - EstFinCHT: "+UF2->UF2_XGERAF+ "- CHAVE CHEQUE: " + UF2->(UF2_FILIAL+UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_NUM) + " VALOR: " + STR(UF2->UF2_VALOR) + " DOC/SERIE: " + UF2->UF2_DOC +"/"+UF2->UF2_SERIE )

	DbSelectArea("UF2")
	UF2->(DbGoTo(nRecUF2))
	If UF2->(!Eof())

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ajusto a database do sistema para a data do movimento.³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dDataBase := UF2->UF2_DATAMO

		SEF->(DbSetOrder(1)) //EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM
		If SEF->(DbSeek(xFilial("SEF")+UF2->UF2_BANCO+UF2->UF2_AGENCI+UF2->UF2_CONTA+UF2->UF2_NUM))
			//RecLock("SEF",.F.)
			//SEF->EF_ORIGEM := ""
			//SEF->(MsUnlock())
			nRecSEF := SEF->(Recno())
		EndIf

		If Sfa390Can(UF2->UF2_BANCO, UF2->UF2_AGENCI, UF2->UF2_CONTA, UF2->UF2_NUM)

			SEF->(DbSetOrder(1)) //EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM
			SEF->(DbGoTo(nRecSEF))
			If SEF->(!Eof()) .OR. SEF->(DbSeek(xFilial("SEF")+UF2->UF2_BANCO+UF2->UF2_AGENCI+UF2->UF2_CONTA+UF2->UF2_NUM))
				RecLock("SEF",.F.)
				SEF->(DbDelete())
				SEF->(MsUnlock())
			EndIf

			cCodBar := UF2->UF2_CODBAR
			lRet := U_TRETE29E(nRecUF2) //limpo campos de usado do cheque

			If lReplica
				U_UREPLICA("UF2", 1, UF2->(UF2_FILIAL+UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_SEQUEN+UF2_NUM), "A")
			EndIf

			If !Empty(cCodBar) //Faz alteração da forma de saída da requisição quando Chq Troco
				U_TRETE29D(cCodBar)
			EndIf

		EndIf

	EndIf

	RestArea(aArea)

Return lRet

//----------------------------------------------------------------------------
// Faz alteração da forma de saída da requisição quando Chq Troco
// cCodbar -> AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL)
//----------------------------------------------------------------------------
User Function TRETE29D(cCodbar, lChqZero)

	Local aArea		  := GetArea()
	Local aAreaU56	  := U56->(GetArea())
	Local aAreaU57    := U57->(GetArea())
	Local aAreaSE5    := SE5->(GetArea())
	Local aAreaSE1    := SE1->(GetArea())
	Local aAreaSA6	  := SA6->(GetArea())
	Local lRet		  := .F.
	Local cPfRqSaq    := AllTrim(SuperGetMV("MV_XPRFXRS", .T., "RPS")) // Prefixo de Titulo de Requisicoes de Saque
	Local cPulaLinha  := chr(13)+chr(10)
	Local nVlCheque := 0
	Local cIdFKAux  := ""
	Default lChqZero := .F.

	DbSelectArea("U57")
	U57->(DbSetOrder(1)) //U57_FILIAL+U57_PREFIX+U57_CODIGO+U57_PARCEL
	If U57->(DbSeek(xFilial("U57")+cCodbar))

		If !lChqZero
			nVlCheque := RetTChTrc(cCodbar)
		EndIf

		DbSelectArea("U56")
		U56->(DbSetOrder(1)) //U56_FILIAL+U56_PREFIX+U56_CODIGO
		U56->(DbSeek(U57->(U57_FILIAL+U57_PREFIX+U57_CODIGO)))

		DbSelectArea("SE1")
		SE1->(DbSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

		cQry := "select SE1.R_E_C_N_O_ AS SE1RECNO" + cPulaLinha
		cQry += " from " + RetSqlName("SE1") + " SE1" + cPulaLinha
		cQry += " where SE1.D_E_L_E_T_ <> '*'" + cPulaLinha
		cQry += " and SE1.E1_FILIAL = '" + xFilial("SE1") + "'" + cPulaLinha
		If U56->U56_TIPO == '1' //PRE PAGA
			cQry += " and E1_PREFIXO = '" + "RPR" + "'" + cPulaLinha
			cQry += " and E1_TIPO = '" + "RA " + "'" + cPulaLinha
		ElseIf U56->U56_TIPO == '2' //POS PAGA
			cQry += " and E1_PREFIXO = '" + IIF(U57->U57_TUSO=="S",cPfRqSaq,"RPC") + "'" + cPulaLinha
			cQry += " and E1_TIPO = '" + "NCC" + "'" + cPulaLinha
		EndIf
		cQry += " and SE1.E1_XCODBAR = '" + AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL) + "'" + cPulaLinha
		cQry += " and SE1.E1_BAIXA <> ''" + cPulaLinha

		If Select("QRYSE1") > 0
			QRYSE1->(DbCloseArea())
		EndIf

		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYSE1" // Cria uma nova area com o resultado do query

		//QRYSE1->(dbEval({|| nCount++}))
		QRYSE1->(dbGoTop())

		If QRYSE1->(!Eof())//SE1->(DbSeek(cChaveSE1))
			While QRYSE1->(!Eof()) //SE1->(!Eof()) .and. AllTrim(cChaveSE1) == AllTrim(SE1->(E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO))
				SE1->(DbGoTo(QRYSE1->SE1RECNO))
				If AllTrim(SE1->E1_XCODBAR) == AllTrim(U57->U57_PREFIX+U57->U57_CODIGO+U57->U57_PARCEL)

					If nVlCheque > SE1->E1_VALOR
						nVlCheque := SE1->E1_VALOR
					EndIf

					//TODO Tratar alteração nas tabelas FK aqui

					//atualiza a SE5
					SE5->(DbSetOrder(7)) //E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ+E5_RECPAG
					If SE5->(DbSeek(xFilial("SE5")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA+'01'+'P')))
						
						cIdFKAux := SE5->E5_IDORIG

						RecLock("SE5",.F.)
						SE5->E5_VALOR 	:= SE1->E1_VALOR - nVlCheque
						If SE1->E1_VALOR - nVlCheque <= 0
							SE5->(DbDelete())
						EndIf
						SE5->(MsUnLock())

						//Excluindo as FK5 que fica la (são duas, do mov e estorno)
						if !empty(cIdFKAux)
							FKA->(DbSetOrder(3)) //FKA_FILIAL+FKA_TABORI+FKA_IDORIG
							FK5->(DbSetOrder(1)) //FK5_FILIAL+FK5_IDMOV
							if FKA->(DbSeek(xFilial("FKA") +"FK5"+ cIdFKAux ))
								cIdFKAux := FKA->FKA_IDPROC
								FKA->(DbSetOrder(2)) //FKA_FILIAL+FKA_IDPROC+FKA_IDORIG+FKA_TABORI
								if FKA->(DbSeek(xFilial("FKA") + cIdFKAux ))
									While FKA->(!Eof()) .AND. FKA->FKA_FILIAL+FKA->FKA_IDPROC == xFilial("FKA") + cIdFKAux
										if FKA->FKA_TABORI == "FK5" .AND. FK5->(DbSeek(xFilial("FK5") + FKA->FKA_IDORIG ))
											RecLock("FK5", .F.)
											FK5->(DbDelete())
											FK5->(MsUnlock())
										endif
										FKA->(DbSkip())
									enddo
								endif
							endif
						endif

						lRet := .T.
					Else
						SET DELETED OFF //Desabilita filtro do campo D_E_L_E_T_
						If SE5->(DbSeek(xFilial("SE5")+SE1->(E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+E1_CLIENTE+E1_LOJA+'01'+'P')))
							If SE5->(Deleted()) .and. (SE1->E1_VALOR - nVlCheque) > 0
								RecLock("SE5")
								SE5->(DbRecall())
								SE5->(MsUnlock())
							EndIf
							RecLock("SE5",.F.)
							SE5->E5_VALOR := SE1->E1_VALOR - nVlCheque
							SE5->(MsUnLock())
							lRet := .T.
						EndIf
						SET DELETED ON //Habilita filtro do campo D_E_L_E_T_
					EndIf

					Exit
				EndIf
				QRYSE1->(DbSkip())
			EndDo
		EndIf

		If Select("QRYSE1") > 0
			QRYSE1->(DbCloseArea())
		EndIf

		If lRet
			//ajusta U57->U57_CHTROC removendo o valor do cheque
			RecLock("U57")
			U57->U57_CHTROC := nVlCheque
			U57->(MsUnLock())
		EndIf

	EndIf

	RestArea(aAreaU57)
	RestArea(aAreaU56)
	RestArea(aAreaSE5)
	RestArea(aAreaSE1)
	RestArea(aAreaSA6)
	RestArea(aArea)

Return lRet

//
// Retorna o total de cheque troco de uma requisição
//
Static Function RetTChTrc(_cCodbar)

	Local nChTroc  := 0
	Local cQry 	   := ""
	Local cLIBCHEQ := SuperGetMV( "MV_LIBCHEQ" , .T./*lHelp*/, "S" )
	Local nLenFilSEF  := len(Alltrim(xFilial("SEF")))

	cQry := "SELECT SUM(UF2.UF2_VALOR) VLCHTROC "
	cQry += " FROM " + RetSqlName("UF2") + " UF2 "
	cQry += " INNER JOIN " + RetSqlName("SEF") + " SEF "
	cQry += 				" ON (SEF.D_E_L_E_T_ <> '*' "
	if nLenFilSEF <> len(Alltrim(xFilial("UF2")))
		cQry += 				" AND SUBSTRING(UF2.UF2_FILIAL,1,"+cValToChar(nLenFilSEF)+") = SUBSTRING(SEF.EF_FILIAL,1,"+cValToChar(nLenFilSEF)+") "
	else
		cQry += 				" AND UF2.UF2_FILIAL = SEF.EF_FILIAL "
	endif
	cQry += 				" AND UF2.UF2_BANCO = SEF.EF_BANCO "
	cQry += 				" AND UF2.UF2_AGENCI = SEF.EF_AGENCIA "
	cQry += 				" AND UF2.UF2_CONTA = SEF.EF_CONTA "
	cQry += 				" AND UF2.UF2_NUM = SEF.EF_NUM "
	If AllTrim(cLIBCHEQ) == "S" // => considera somente os cheque troco com financeiro
		cQry += 			" AND SEF.EF_LIBER = 'S' " 
	EndIf
	cQry += 				" ) "
	cQry += " WHERE UF2.D_E_L_E_T_ = ' ' "
	cQry += " AND UF2.UF2_CODBAR = '" + _cCodbar + "' "

	If Select("QRYUF2")>0
		QRYUF2->(DbCloseArea())
	EndIf

	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYUF2" // Cria uma nova area com o resultado do query

	If QRYUF2->(!Eof())
		nChTroc := QRYUF2->VLCHTROC
	EndIf

	If Select("QRYUF2")>0
		QRYUF2->(DbCloseArea())
	EndIf

Return nChTroc

//-------------------------------------------------------
// rotina que cancela cheques avulsos (Cheque Troco)
//-------------------------------------------------------
User Function TR029CAN(cBanco, cAgencia, cConta, cCheque)
Return Sfa390Can(cBanco, cAgencia, cConta, cCheque)
Static Function Sfa390Can(cBanco, cAgencia, cConta, cCheque)

	LOCAL lF390Canc := ExistBlock("F390CANC")
	LOCAL lF390CBX	:= ExistBlock("F390CBX")
	LOCAL lRet		:= .F.
	LOCAL cAlias	:= Alias()
	LOCAL nOrder	:= IndexOrd()
	LOCAL nRec		:= Recno()
	LOCAL lAvulso	:= .F.
	LOCAL lCancelou := .F.
	LOCAL lMostra	:= .T.

	PRIVATE cBanco390 	:= cBanco
	PRIVATE cAgencia390 := cAgencia
	PRIVATE cConta390 	:= cConta
	PRIVATE cCheque390 	:= cCheque
	PRIVATE nOpcA 		:= 0
//???????????????????????????????????????????????????????????????ø
//? VerIfica o numero do Lote 									 ?
//¿???????????????????????????????????????????????????????????????
	PRIVATE cLote
	LoteCont( "FIN" )

//Conout(" *** Sfa390Can - INICIO *** ")

	If !Empty(cBanco390)

		If !Empty(cBanco390) .And. Fa390Banco(3) .And. Fa390Cheq(2)
			nOpcA := 1
		EndIf

		If nOpcA == 1
			//cheque foi posicionado pela funcao Fa390Cheq(2)
			lAvulso := ( Alltrim(SEF->EF_ORIGEM) == "FINA390AVU" )

			If  SEF->EF_IMPRESS == "C"
				//Help( " ", 1, "JA CANCELA")
				//Conout(" *** Sfa390Can - Cheque ja cancelado. *** ")
				Return lRet
			Else
				//limpo campo impresso para nao aparecer pergunta padrão de inutilizar cheque SEF.
				Reclock("SEF", .F.)
				SEF->EF_IMPRESS := " "
				SEF->(MsUnlock())
			EndIf

			//!Fa390ExistRed(cBanco390,cAgencia390,cConta390,cCheque390) -> VerIfica se existe redeposito para o cheque (foi removido essa validação)
			//Ponto de entrada para permissao ou nao do cancelamento do cheque
			If lF390Canc
				If !(ExecBlock("F390CANC",.F.,.F.))
					Return lRet
				EndIf
			EndIf

			BEGIN TRANSACTION
				lMostra		:= .F.
				lCancelou	:= IIf( SEF->EF_ORIGEM <> "FINA550", fa390ver(lMostra,,lAvulso), .F. )
			END TRANSACTION

			If lCancelou != Nil .And. !lCancelou
				// No retorno da Fa390Ver, o SE2 e o SEF estao posicionados nos
				// registros que foram invalidados.
				If Alltrim( SEF->EF_ORIGEM ) == "FINA550"
					//Help( " ", 1, "ORIGEM190")
					//Conout(" *** Sfa390Can - Problema de origem: ORIGEM190. *** ")
				ElseIf Empty( SE2->E2_IMPCHEQ ) .Or. Alltrim( SEF->EF_ORIGEM ) == "FINA550"
					//Help( " ", 1, "ORIGEM390" )
					//Conout(" *** Sfa390Can - Problema de origem: ORIGEM390. *** ")
				ElseIf SEF->EF_IMPRESS == "C"
					//Help( " ", 1, "JA CANCELA")
					//Conout(" *** Sfa390Can - Cheque ja cancelado. *** ")
				EndIf
			ElseIf lCancelou == Nil
				//Ponto de entrada para complementos de gravacao apos cancelamento do cheque
				If lF390CBX
					ExecBlock("F390CBX",.F.,.F.)
				EndIf
				lRet := .T.
			EndIf
			//Else
			//Help( " ", 1, "HA_REDEPOS" )//"Já existe redeposito para este cheque, não é permitido seu cancelamento. Para estornar completamente o movto. deste cheque, efetue o redepósito do restante do cheque.
			//	conout(" *** Sfa390Can - Já existe redeposito para este cheque, não é permitido seu cancelamento. Para estornar completamente o movto. deste cheque, efetue o redepósito do restante do cheque. *** ")
			//EndIf
		EndIf
	EndIf

//Conout(" *** Sfa390Can - FIM *** ")
	DbSelectArea( cAlias )
	DbSetOrder( nOrder )
	DbGoto( nRec )

Return lRet

//-----------------------------------------------------------------
// Função que limpa utilização do cheque troco -> LimpaUsoUF2
//-----------------------------------------------------------------
User Function TRETE29E(nRecUF2)

	Local lRet := .F.
	Local lZeraUF2 := SuperGetMV("TP_ZERAUF2", .F., .T.) //Zera o valor do cheque troco quando processa estorno? (default .T.)
	Local lChTrOp := SuperGetMV("MV_XCHTROP",,.F.) //Controle de Cheque Troco por Operador (default .F.)

	UF2->(DbGoTo(nRecUF2))
	If UF2->(!Eof())
		RecLock("UF2")
		If lZeraUF2
		UF2->UF2_VALOR 	:= 0
		EndIf
		UF2->UF2_STATUS	:= "1"
		UF2->UF2_DOC   	:= ""
		UF2->UF2_SERIE 	:= ""
		UF2->UF2_CODBAR	:= ""
		UF2->UF2_CLIENT := ""
		UF2->UF2_LOJACL	:= ""
		UF2->UF2_NATURE	:= ""
		UF2->UF2_XGERAF := ""
		UF2->UF2_XOPERA	:= ""
		UF2->UF2_XPDV	:= ""
		If lChTrOp  // Felipe 23/01/2023 - Chamado POSTO-327
			UF2->UF2_PDV	:= LJGetStation("LG_PDV")
		EndIf
		UF2->UF2_XESTAC	:= ""
		UF2->UF2_XNUMMO	:= ""
		UF2->UF2_XHORA	:= ""
		UF2->UF2_DATAMO	:= stod("")
		lRet := .T.
		UF2->(MsUnlock())
	Else
		lRet := .F.
	EndIf

Return lRet

//---------------------------------------------------------------------
// Ajusta o valor do troco de cada cheque troco do cupom -> AjustaTC
//---------------------------------------------------------------------
User Function TRETE29F(nChTrc)

	Local aArea		:= GetArea()
	Local aAreaSE5  := SE5->(GetArea())
	Local aAreaSA6  := SA6->(GetArea())
	Local cPrefixo 	:= IIf(EMPTY(SL1->L1_SERIE),SL1->L1_SERPED,SL1->L1_SERIE)
	Local cNum 		:= IIf(EMPTY(SL1->L1_DOC),SL1->L1_DOCPED,SL1->L1_DOC)

	Local cBanco    := "" //banco do caixa
	Local cAgencia  := ""
	Local cNumCon   := ""

	Local cData     := DtoS(SL1->L1_EMISNF)
	Local cCliente  := SL1->L1_CLIENTE
	Local cLoja     := SL1->L1_LOJA
	Local cCondicao	:= ""
	Local bCondicao
	Local aDados 	:= {}
	Local cIdFKAux  := ""
	Local lOk := .T.
	Default nChTrc  := 0 //total do cheque troco

	//Conout(" >> TRETE029 - INICIO: Ajuste do Cheque Troco")

	SA6->(DbSetOrder(1))
	If (SA6->(DbSeek(xFilial("SA6")+SL1->L1_OPERADO))) //posiciona no banco do caixa (operador) que finalizou a venda
		//If ChecaUserCX() //checa usuario caixa e posiciona na SA6

		cBanco    := SA6->A6_COD 		//banco do caixa
		cAgencia  := SA6->A6_AGENCIA 	//agencia do caixa
		cNumCon   := SA6->A6_NUMCON 	//conta do caixa

		cCondicao := " E5_FILIAL = '"+xFilial("SE5")+"'"
		cCondicao += " .AND. E5_TIPODOC $ 'VL/TR'"
		cCondicao += " .AND. E5_PREFIXO = '"+cPrefixo+"'"
		cCondicao += " .AND. E5_NUMERO = '"+cNum+"'"
		cCondicao += " .AND. E5_BANCO = '"+cBanco+"'"
		cCondicao += " .AND. E5_AGENCIA = '"+cAgencia+"'"
		cCondicao += " .AND. E5_CONTA = '"+cNumCon+"'"
		cCondicao += " .AND. DTOS(E5_DATA) = '"+cData+"'"
		cCondicao += " .AND. E5_CLIFOR = '"+cCliente+"'"
		cCondicao += " .AND. E5_LOJA = '"+cLoja+"'"
		cCondicao += " .AND. E5_MOEDA = 'TC'"
		cCondicao += " .AND. E5_VALOR > 0"

		//Conout(cCondicao)

		// limpo os filtros da SE5
		SE5->(DbClearFilter())

		// executo o filtro na SE5
		bCondicao 	:= "{|| " + cCondicao + " }"
		SE5->(DbSetFilter(&bCondicao,cCondicao))

		// vou para a primeira linha
		SE5->(DbGoTop())

		While !SE5->(EOF()) .and. nChTrc > 0

			If SE5->E5_VALOR <= nChTrc
				nChTrc := nChTrc - SE5->E5_VALOR

				cIdFKAux := SE5->E5_IDORIG
				lOk := .T.
				If ExistFunc("LjNewGrvTC") .And. LjNewGrvTC() //Verifica se o sistema est?atualizado para executar o novo procedimento para grava?o dos movimentos de troco.
					aDados := {}
					//cDescErro:=""
					lMsErroAuto := .F.
					aAdd( aDados, {"E5_DATA"    , SE5->E5_DATA     	, NIL} )
					aAdd( aDados, {"E5_MOEDA" 	, SE5->E5_MOEDA    	, NIL} )
					aAdd( aDados, {"E5_VALOR"   , SE5->E5_VALOR    	, NIL} )
					aAdd( aDados, {"E5_NATUREZ" , SE5->E5_NATUREZ  	, NIL} )
					aAdd( aDados, {"E5_BANCO" 	, SE5->E5_BANCO  	, NIL} )
					aAdd( aDados, {"E5_AGENCIA" , SE5->E5_AGENCIA  	, NIL} )
					aAdd( aDados, {"E5_CONTA" 	, SE5->E5_CONTA  	, NIL} )
					aAdd( aDados, {"E5_HISTOR" 	, SE5->E5_HISTOR  	, NIL} )
					aAdd( aDados, {"E5_TIPOLAN" , SE5->E5_TIPOLAN  	, NIL} )

					MsExecAuto( {|w,x, y| FINA100(w, x, y)}, 0, aDados, 5 ) //5=Exclusão de Movimento

					If lMsErroAuto
						//cDescErro:= MostraErro("\")
						//cDescErro := "Erro de Exclusão do troco na Rotina Automatica FINA100:" + Chr(13) + cDescErro 
						lOk := .F.
						EXIT
					EndIf
				else
					RecLock("SE5", .F.)
					SE5->(DbDelete())
					SE5->(MsUnlock())
				endif

				//Excluindo as FK5 que fica la (são duas, do mov e estorno)
				if lOk .AND. !empty(cIdFKAux)
					FKA->(DbSetOrder(3)) //FKA_FILIAL+FKA_TABORI+FKA_IDORIG
					FK5->(DbSetOrder(1)) //FK5_FILIAL+FK5_IDMOV
					if FKA->(DbSeek(xFilial("FKA") +"FK5"+ cIdFKAux ))
						cIdFKAux := FKA->FKA_IDPROC
						FKA->(DbSetOrder(2)) //FKA_FILIAL+FKA_IDPROC+FKA_IDORIG+FKA_TABORI
						if FKA->(DbSeek(xFilial("FKA") + cIdFKAux ))
							While FKA->(!Eof()) .AND. FKA->FKA_FILIAL+FKA->FKA_IDPROC == xFilial("FKA") + cIdFKAux
								if FKA->FKA_TABORI == "FK5" .AND. FK5->(DbSeek(xFilial("FK5") + FKA->FKA_IDORIG ))
									RecLock("FK5", .F.)
									FK5->(DbDelete())
									FK5->(MsUnlock())
								endif
								FKA->(DbSkip())
							enddo
						endif
					endif
				endif
				//Conout("   >> TROCO DA VENDA (R$), AJUSTADO PARA = " + cValToChar(0))
			Else
				RecLock("SE5",.F.)
				SE5->E5_VALOR := SE5->E5_VALOR - nChTrc
				SE5->(MsUnlock())

				FK5->(DbSetOrder(1)) //FK5_FILIAL+FK5_IDMOV
				if !empty(SE5->E5_IDORIG) .AND. FK5->(DbSeek(xFilial("FK5") + SE5->E5_IDORIG ))
					RecLock("FK5", .F.)
					FK5->FK5_VALOR := FK5->FK5_VALOR - nChTrc
					FK5->(MsUnlock())
				endif
				
				nChTrc := nChTrc - nChTrc
				//Conout("   >> TROCO DA VENDA (R$), AJUSTADO PARA = " + cValToChar(SE5->E5_VALOR - nChTrc))
			EndIf

			SE5->(DbSkip())
		EndDo

		// limpo os filtros da SE5
		SE5->(DbClearFilter())

	EndIf

	RestArea(aAreaSA6)
	RestArea(aAreaSE5)
	RestArea(aArea)

Return(nChTrc)

//--------------------------------------
// Cancela o Financeiro do CHEQUE
//--------------------------------------
User Function TRETE29G(lAjuTroco, lTransaction, lAuto, lInutiliza, cMsgErro)

	Local aArea := GetArea()
	Local aAreaSLW := SLW->(GetArea())
	Local lTOk := .T.
	Local cChvChqAnt, _cDoc, _cSerie, _cCodbar, _nVlrchq
	Default lAjuTroco := .T. //se irá ajustar troco automatico ou nao
	Default lTransaction := .T. //se irá utilizar controle de transação
	Default lAuto := .F. //se executa automatico, sem interação do usuário
	Default lInutiliza := .T. //define se inutiliza ou nao o cheque troco
	Default cMsgErro := ""

	If UF2->UF2_DATAMO < GETMV("MV_DATAFIN") //Fabio Pires - 23-02-16
		cMsgErro := "Não é possível excluir o cheque troco. A data limite p/ realização de operações financeiras se encontra fechada."
		If !lAuto
			MsgAlert(cMsgErro,"Atenção")
		EndIf
		RestArea(aAreaSLW)
		RestArea(aArea)
		Return .F.
	ElseIf UF2->UF2_DATAMO < GETMV("MV_DATAREC") //Fabio Pires - 23-02-16
		cMsgErro := "Não é possível excluir o cheque troco. A data limite p/ realização de operações financeiras se encontra fechada."
		If !lAuto
			MsgAlert(cMsgErro,"Atenção")
		EndIf
		RestArea(aAreaSLW)
		RestArea(aArea)
		Return .F.
	EndIf

//verifico se o caixa está fechado e conferido
	SLW->(DbSetOrder(3)) //LW_FILIAL+LW_PDV+LW_OPERADO+DTOS(LW_DTABERT)+LW_ESTACAO+LW_NUMMOV
	If SLW->(DbSeek(xFilial("SLW")+UF2->UF2_XPDV+UF2->UF2_XOPERA+DTOS(UF2->UF2_DATAMO)+UF2->UF2_XESTAC+UF2->UF2_XNUMMO  ))
		If SLW->LW_CONFERE == "1" //conferido
			cMsgErro := "Não é possível excluir o cheque troco. O caixa em que foi utilzado ja foi conferido."
			If !lAuto
				MsgAlert(cMsgErro,"Atenção")
			EndIf
			RestArea(aAreaSLW)
			RestArea(aArea)
			Return .F.
		EndIf
	EndIf

	If !U_TRETE29K(lAuto,@cMsgErro) //validação se tem SE5 e se está conciliado
		RestArea(aAreaSLW)
		RestArea(aArea)
		Return .F.
	EndIf

	If lTransaction
		BeginTran() //controle de transação
	EndIf

//posiciono no cheque troco do grid (antigo)
	cChvChqAnt 	:= UF2->(UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_NUM)
	_cDoc 		:= UF2->UF2_DOC
	_cSerie 	:= UF2->UF2_SERIE
	_cCodbar 	:= UF2->UF2_CODBAR
	_nVlrchq 	:= UF2->UF2_VALOR

//excluo o cheque troco
	If (UF2->UF2_STATUS=='2' .and. !EMPTY(UF2->UF2_DOC) .and. !EMPTY(UF2->UF2_SERIE))
		If lAuto .OR. MsgYesNo("Confirma a exclusão financeira do cheque troco?","Atenção")
			If (AllTRim(_cSerie) == AllTrim(SuperGetMV("MV_XPRFXRS", .T., "RPS")))
				lTOk := U_TRETE29I( "", "", _cCodbar, cChvChqAnt, .T., .T.) //rotina de exclusao de cheque troco
			Else
				lTOk := U_TRETE29I( _cDoc, _cSerie, "", cChvChqAnt, .T., .T. ) //rotina de exclusao de cheque troco
			EndIf

			If lTOk
				If lAjuTroco
					If AllTrim(_cSerie) == AllTrim(SuperGetMv("MV_XPFXCOM",.F.,"CMP")) //se compensação
						//inclui o valor do cheque troco como dinheiro na compensação
						If !U_TRETE29J(2, _nVlrchq, _cDoc)
							cMsgErro := "Não foi possível excluir cheque troco. Entre em contato com administrador do sistema."
							If !lAuto
								MsgAlert(cMsgErro,"Msg: TRETE29I")
							EndIf
							lTOk := .F.
						EndIf
					ElseIf AllTRim(_cSerie) == AllTrim(SuperGetMV("MV_XPRFXRS", .T., "RPS")) //requisição de saque (vale motorista)
						//inclui o valor do cheque troco como dinheiro na requisição de saque (PRE OU POS)
						If !U_TRETE29D( _cCodbar )
							cMsgErro := "Não foi possível excluir cheque troco. Entre em contato com administrador do sistema."
							If !lAuto
								MsgAlert(cMsgErro,"Msg: TRETE29D")
							EndIf
							lTOk := .F.
						EndIf
					Else //venda
						//inclui valor do cheque troco como dinheiro na venda
						If !U_UAJTROCO(2, _nVlrchq, _cDoc, _cSerie, 1)
							cMsgErro := "Não foi possível alterar cheque troco. Entre em contato com administrador do sistema."
							If !lAuto
								MsgAlert(cMsgErro,"Msg: UAJTROCO")
							EndIf
							lTOk := .F.
						EndIf
					EndIf
				EndIf
			Else
				cMsgErro := "Não foi possível excluir cheque troco. Entre em contato com administrador do sistema."
				If !lAuto
					MsgAlert(cMsgErro,"Msg: TRETE29I")
				EndIf
				lTOk := .F.
			EndIf
		Else
			lTOk := .F.
		EndIf
	Else
		lTOk := .F.
		cMsgErro := "Cheque troco não utilizado! Ação não permitida"
		If !lAuto
			MsgInfo(cMsgErro,"Atenção")
		EndIf
	EndIf

	If lTOk
		If !lAuto
			MsgInfo("Exclusão do cheque ocorrida com sucesso!","Atenção!")
		EndIf
		If lInutiliza .AND. (lAuto .OR. MsgYesNo("Deseja inutilizar o cheque troco?","Atenção"))
			U_TRETE29H()
		EndIf
	ElseIf !lTOk .and. lTransaction
		DisarmTransaction()
	EndIf

	If lTransaction
	EndTran()
EndIf

RestArea(aAreaSLW)
RestArea(aArea)

Return lTOk

//------------------------------------------------------------------------
// Inutilizar a folha de cheque troco
//------------------------------------------------------------------------
User Function TRETE29H(lAuto)

	Local lTOk := .F.
	Local lZeraUF2 := SuperGetMV("TP_ZERAUF2", .F., .T.) //Zera o valor do cheque troco quando processa estorno? (default .T.)
	Local lChTrOp := SuperGetMV("MV_XCHTROP",,.F.) //Controle de Cheque Troco por Operador (default .F.)
	Default lAuto := .F.

//excluo o cheque troco
	If UF2->UF2_STATUS <> '2' .and. UF2->UF2_STATUS <> '3' .and. EMPTY(UF2->UF2_DOC) .and. EMPTY(UF2->UF2_SERIE) .and. EMPTY(UF2->UF2_CODBAR)

		If lAuto .OR. MsgYesNo("Confirma a inutilização da folha de cheque troco N. " + AllTrim(UF2->UF2_NUM) + "?","Atenção")

			RecLock("UF2")
			UF2->UF2_STATUS	:= "3"
			UF2->UF2_CODCX	:= ""
			UF2->UF2_PDV	:= ""
			if lZeraUF2
				UF2->UF2_VALOR 	:= 0
			endif
			UF2->UF2_DOC   	:= ""
			UF2->UF2_SERIE 	:= ""
			UF2->UF2_CODBAR	:= ""
			UF2->UF2_CLIENT := ""
			UF2->UF2_LOJACL	:= ""
			UF2->UF2_NATURE	:= ""
			UF2->UF2_XGERAF := ""
			UF2->UF2_XOPERA	:= ""
			UF2->UF2_XPDV	:= ""
			If lChTrOp  // Felipe 23/01/2023 - Chamado POSTO-327
				UF2->UF2_PDV	:= LJGetStation("LG_PDV")
			EndIf
			UF2->UF2_XESTAC	:= ""
			UF2->UF2_XNUMMO	:= ""
			UF2->UF2_XHORA	:= ""
			UF2->UF2_DATAMO	:= dDataBase
			UF2->(MsUnlock())
			U_UREPLICA("UF2", 1, UF2->(UF2_FILIAL+UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_SEQUEN+UF2_NUM), "A")

			If !lAuto
				MsgInfo("Inutilização da folha de cheque troco ocorrida com sucesso!","Atenção!")
			EndIf
			lTOk := .T.
		EndIf
	ElseIf !lAuto
		If UF2->UF2_STATUS == '3'
			MsgStop("Cheque já inutilizado!","Atenção!")
		Else
			MsgStop("Não é possivel inutilizar uma folha de cheque utilizada. Favor excluir o financeiro!","Atenção!")
		EndIf
	EndIf

Return lTOk

//------------------------------------------------------------------------
// Rotina que exclui os cheque troco e volta o status dos cheques trocos
// utilizados em um cupom fiscal
//------------------------------------------------------------------------
User Function TRETE29I(cL1_DOC,cL1_SERIE,cUF2_CODBAR,cChavChq,lReplica,lEstFor)

	Local aArea		:= GetArea()
	Local aAreaUF2	:= UF2->(GetArea())
	Local aAreaSEF	:= SEF->(GetArea())
	Local lRet		:= .T.
	Local nX		:= 0
	Local aRecUF2	:= {}
	Local cCondicao	:= ""

	Default cL1_DOC		:= Space(TamSX3("L1_DOC")[1])
	Default cL1_SERIE	:= Space(TamSX3("L1_SERIE")[1])
	Default cUF2_CODBAR	:= Space(TamSX3("UF2_CODBAR")[1])
	Default cChavChq    := "" // para exclusao de um cheque troco especifico
	Default lReplica	:= .T.
	Default lEstFor		:= .T. //variavel para forçar estorno financeiro, sem ser via job

	cL1_DOC := PadR(cL1_DOC, TamSX3("L1_DOC")[1], " ")
	cL1_SERIE := PadR(cL1_SERIE, TamSX3("L1_SERIE")[1], " ")

//Conout("TRETE29I - EXCLUSAO DE CH TROCO >> HR INICIO: "+AllTrim(Time()))

	DbSelectArea("UF2")
	If !Empty(cL1_DOC) .and. !Empty(cL1_SERIE)

		cCondicao := " UF2_FILIAL = '" + xFilial("UF2") + "'"
		cCondicao += " .AND. UF2_DOC = '" + cL1_DOC + "'"
		cCondicao += " .AND. UF2_SERIE = '" + cL1_SERIE + "'"

	ElseIf !Empty(cUF2_CODBAR)

		cCondicao := " UF2_FILIAL = '" + xFilial("UF2") + "'"
		cCondicao += " .AND. UF2_CODBAR = '" + cUF2_CODBAR + "'"

	EndIf

//somente se montou filtros
	If !Empty(cCondicao)
		// limpo os filtros da UF2
		UF2->(DbClearFilter())

		// executo o filtro na UF2
		bCondicao 	:= "{|| " + cCondicao + " }"
		UF2->(DbSetFilter(&bCondicao,cCondicao))

		// vou para a primeira linha
		UF2->(DbSetOrder(1))
		UF2->(DbGoTop())
		While UF2->(!Eof())

			AADD(aRecUF2, UF2->(Recno()) )

			UF2->(DbSkip())
		Enddo

		// limpo os filtros da SL1
		UF2->(DbClearFilter())
	EndIf

	If !Empty(aRecUF2)

		For nX:=1 to Len(aRecUF2)

			UF2->(DbGoTo(aRecUF2[nX]))
			nRecUF2	:= UF2->(Recno())

			If UF2->(!Eof()) .and. Empty(cChavChq) .or. AllTrim(cChavChq) == Alltrim(UF2->(UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_NUM))
				If UF2->UF2_XGERAF == "G" //ja gerou o financeiro

					If lEstFor //se estorno forçado
						lRet := U_TRETE29C(nRecUF2,lReplica)
					Else //senao, estorno será via job TRETE026. Grava flag estorno
						If RecLock("UF2", .F.)
							If lReplica
								UF2->UF2_XGERAF := "E" //flag estorno com replica
							Else
								UF2->UF2_XGERAF := "X" //flag estorno sem replica
							EndIf
							UF2->(MsUnlock())
							//lRet := .T.
						EndIf
					EndIf

				ElseIf UF2->UF2_XGERAF == "P" //ainda esta pendente para gerar o financeiro
					lRet := U_TRETE29E(nRecUF2) //limpo campos de usado do cheque
					If lReplica
						U_UREPLICA("UF2", 1, UF2->(UF2_FILIAL+UF2_BANCO+UF2_AGENCI+UF2_CONTA+UF2_SEQUEN+UF2_NUM), "A")
					EndIf
					//nao faz replica pois ja foi limpado no PDV os campos
				Else
					lRet := .F.
				EndIf
			EndIf

		Next nX
	Else
		lRet := .F.
	EndIf

//Conout("TRETE29I - EXCLUSAO DE CH TROCO >> HR FIM: "+AllTrim(Time()))

	RestArea(aAreaSEF)
	RestArea(aAreaUF2)
	RestArea(aArea)

Return lRet

//----------------------------------------------------------------------------
// Faz alteração da forma de saída da compensaçao quando Dinheiro/ChqTroco
// nOpcxCp:  1=Remove Dinheiro e Add ChqTroco
//			 2=Adiciona Dinheiro e Remove ChqTroco
// 		     3=Remove Dinheiro e Add Vale Haver
//			 4=Adiciona Dinheiro e Remove Vale Haver
//			 5=Adiciona Dinheiro (quando altera valor)
//			 6=Remove Dinheiro (quando altera valor)
//----------------------------------------------------------------------------
User Function TRETE29J(nOpcx, nValorAlt, cDoc)

	Local lRet := .T.
	Local aFin040 := {}
	Local nOpcxCp := 0
	Local cChvSE1 := ""
	Local dBkpDBase := dDataBase

	If nValorAlt <= 0
		Return .F.
	EndIf

	UC0->(DbSetOrder(1))
	If UC0->(DbSeek(xFilial("UC0")+cDoc))
		If (nOpcx == 1 .OR. nOpcx == 3 .OR. nOpcx == 6) .AND. (UC0->UC0_VLDINH - nValorAlt) < 0 //valor negativo
			Return .F. //aborta
		EndIf

		RecLock("UC0", .F.)
		If nOpcx == 1 .OR. nOpcx == 3 .OR. nOpcx == 6
			UC0->UC0_VLDINH -= nValorAlt
			If nOpcx == 1
				UC0->UC0_VLCHTR += nValorAlt
			ElseIf nOpcx == 3
				UC0->UC0_VLVALE += nValorAlt
			EndIf

			If UC0->UC0_VLDINH == 0
				nOpcxCp := 5
			Else
				nOpcxCp := 4
			EndIf
		Else
			If UC0->UC0_VLDINH == 0
				nOpcxCp := 3
			Else
				nOpcxCp := 4
			EndIf
			UC0->UC0_VLDINH += nValorAlt
			If nOpcx == 2
				UC0->UC0_VLCHTR -= nValorAlt
			ElseIf nOpcx == 4
				UC0->UC0_VLVALE -= nValorAlt
			EndIf
		EndIf
		UC0->UC0_VLTOT := UC0->UC0_VLDINH + UC0->UC0_VLCHTR + UC0->UC0_VLVALE
		UC0->(MsUnlock())
	Else
		Return .F. //aborta
	EndIf

	cChvSE1 := xFilial("SE1")+PadR(SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",),TamSx3("E1_PREFIXO")[1])+UC0->UC0_NUM+Space(TamSx3("E1_PARCELA")[1])+"NCC"

	//EXCLUIR BAIXA NO CAIXA QUE FEZ A COMPENSAÇÃO E EXCLUIR NCC DO DINHEIRO
	If nOpcxCp == 3 .OR. SE1->(DbSeek(xFilial("SE1")+PadR(SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",),TamSx3("E1_PREFIXO")[1])+UC0->UC0_NUM+Space(TamSx3("E1_PARCELA")[1])+"NCC" ))
		If nOpcxCp == 3 .OR. (!empty(SE1->E1_BAIXA) .AND. CancBxSE1()) //cancela a baixa
			If nOpcxCp == 5	//chama Exclusao do titulo

				If !ExcSE1(0,"")
					lRet := .F. //erro
				EndIf

			Else //altera

				//GERA NCC DO DINHEIRO E FAZ BAIXA NO CAIXA QUE FEZ A COMPENSACAO
				If UC0->UC0_VLDINH > 0

					aFin040		:= {}

					dDataBase := UC0->UC0_DATA

					AADD( aFin040, {"E1_FILIAL"  , xFilial("SE1")  ,Nil})
					AADD( aFin040, {"E1_PREFIXO" , SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",)     ,Nil}) //COMPENSAÇÃO
					AADD( aFin040, {"E1_NUM"     , UC0->UC0_NUM	   ,Nil})
					AADD( aFin040, {"E1_PARCELA" , Space(TamSx3("E1_PARCELA")[1])			   ,Nil})
					AADD( aFin040, {"E1_TIPO"    , "NCC"		   ,Nil}) //NCC pois é um crédito que o cliente vai sacar
					AADD( aFin040, {"E1_CLIENTE" , UC0->UC0_CLIENT ,Nil})
					AADD( aFin040, {"E1_LOJA"    , UC0->UC0_LOJA   ,Nil})
					If SE1->(FieldPos("E1_DTLANC")) > 0
						AADD( aFin040, {"E1_DTLANC"	 , UC0->UC0_DATA   ,Nil})
					EndIf
					AADD( aFin040, {"E1_EMISSAO" , UC0->UC0_DATA   ,Nil})
					AADD( aFin040, {"E1_VENCTO"  , UC0->UC0_DATA   ,Nil})
					AADD( aFin040, {"E1_VENCREA" , DataValida(UC0->UC0_DATA),Nil})
					AADD( aFin040, {"E1_VALOR"   , UC0->UC0_VLDINH ,Nil})
					AADD( aFin040, {"E1_NATUREZ" , SuperGetMv( "MV_XCNATDI"	, .F. , "DINHEIRO",)  ,Nil})
					AADD( aFin040, {"E1_XPLACA"	 , UC0->UC0_PLACA  ,Nil})
					AADD( aFin040, {"E1_XPDV"	 , UC0->UC0_PDV	   ,Nil})
					AADD( aFin040, {"E1_ORIGEM"  , "TRETE024"      ,Nil})

					Private lMsErroAuto := .F.
					Private lMsHelpAuto := .T.

					MSExecAuto({|x,y| Fina040(x,y)}, aFin040, nOpcxCp)

					If !lMsErroAuto

						XcBanco    := UC0->UC0_OPERAD
						XcAgencia  := Posicione("SA6",1,xFilial("SA6")+UC0->UC0_OPERAD,"A6_AGENCIA")
						XcNumCon   := Posicione("SA6",1,xFilial("SA6")+UC0->UC0_OPERAD,"A6_NUMCON")

						If !empty(XcAgencia)
							If BaixaSE1(XcBanco, XcAgencia, XcNumCon, cChvSE1)
								RecLock("SE5",.F.)
								SE5->E5_XPDV 	:= UC0->UC0_PDV
								SE5->E5_XESTAC 	:= UC0->UC0_ESTACA
								SE5->E5_NUMMOV 	:= UC0->UC0_NUMMOV
								SE5->E5_XHORA 	:= UC0->UC0_HORA
								SE5->(MsUnLock())
							Else
								lRet := .F. //erro
							EndIf
						Else
							lRet := .F. //erro
						EndIf

					Else
						If !IsBlind()
							MostraErro()
						Else
							cErroExec := MostraErro("\temp")
							//Conout(" ============ ERRO =============")
							//Conout(cErroExec)
							cErroExec := ""
						EndIf
						lRet := .F. //erro
					EndIf

					dDataBase := dBkpDBase
				Else
					lRet := .F. //erro
				EndIf

			EndIf
		Else
			lRet := .F. //erro
		EndIf
	Else
		lRet := .F. //erro
		//Conout("DoAlteraDinCmp:  Não posicionou no titulo: " + xFilial("SE1")+PadR(SuperGetMv( "MV_XPFXCOM" , .F. , "CMP",),TamSx3("E1_PREFIXO")[1])+UC0->UC0_NUM+Space(TamSx3("E1_PARCELA")[1])+"NCC" )
	EndIf

Return lRet

//----------------------------------------------------------------------------------------------
// Verifica se um cheque troco está conciliado. Deve estar posicionado na UF2 -> CHTConciliado
//----------------------------------------------------------------------------------------------
User Function TRETE29K(lAuto, cMsgErro)

	Local lRet := .T.
	Local cChavChq := xFilial("SE5")+PadR(UF2->UF2_BANCO,TamSX3("E5_BANCO")[1])+PadR(UF2->UF2_AGENCI,TamSX3("E5_AGENCIA")[1])+PadR(UF2->UF2_CONTA,TamSX3("E5_CONTA")[1])+PadR(UF2->UF2_NUM,TamSX3("E5_NUMCHEQ")[1])

	SEF->(DbSetOrder(1)) //EF_FILIAL+EF_BANCO+EF_AGENCIA+EF_CONTA+EF_NUM
	If SEF->(DbSeek(xFilial("SEF")+UF2->UF2_BANCO+UF2->UF2_AGENCI+UF2->UF2_CONTA+UF2->UF2_NUM))
	
		SE5->(DbSetOrder(17)) //E5_FILIAL+E5_BANCO+E5_AGENCIA+E5_CONTA+E5_NUMCHEQ+E5_TIPODOC+E5_SEQ
		If SE5->(DbSeek(cChavChq))
			While SE5->(!Eof()) .AND. (SE5->E5_FILIAL+SE5->E5_BANCO+SE5->E5_AGENCIA+SE5->E5_CONTA+SE5->E5_NUMCHEQ) == cChavChq

				If UPPER(SE5->E5_RECONC) == "X"
					lRet := .F.
					cMsgErro := "Ação negada. Movimentação bancária (SE5) já se encontra conciliada!"
					If !lAuto
						MsgAlert(cMsgErro,"Atenção")
					EndIf
					EXIT //sai do While
				elseif Upper(Alltrim(SE5->E5_LA)) == "S"
					lRet := .F.
					cMsgErro := "Ação negada. Movimento de troco já se encontra contabilizado! Estorne a contabilização e tente novamente."
					if !lAuto
						MsgAlert(cMsgErro,"Atenção")
					endif
					EXIT //sai do While
				EndIf

				If SE5->E5_SITUACA <> 'C'
					If SE5->E5_DTDISPO < GETMV("MV_DATAFIN") //Fabio Pires - 23-02-16
						lRet := .F.
						cMsgErro := "Não é possível substituir o cheque troco. A data limite p/ realização de operações financeiras se encontra fechada."
						If !lAuto
							MsgAlert(cMsgErro,"Atenção")
						EndIf
						EXIT //sai do While
					EndIf
					
					If SE5->E5_DTDISPO < GETMV("MV_DATAREC") //Fabio Pires - 23-02-16
						lRet := .F.
						cMsgErro := "Não é possível substituir o cheque troco. A data limite p/ realização de operações financeiras se encontra fechada."
						If !lAuto
							MsgAlert(cMsgErro,"Atenção")
						EndIf
						EXIT //sai do While
					EndIf
				EndIf

				SE5->(DbSkip())
			EndDo
		ElseIf SEF->EF_LIBER == "S" //deveria possuir financeiro
			lRet := .F.
			cMsgErro := "Ação negada. Movimentação bancária (SE5) não encontrada!"
			If !lAuto
				MsgAlert(cMsgErro,"Atenção")
			EndIf
		EndIf
	
	Else
		lRet := .F.
		cMsgErro := "Ação negada. Dados do cheque (SEF) não encontrado!"
		If !lAuto
			MsgAlert(cMsgErro,"Atenção")
		EndIf
	EndIf

Return lRet

/*
-----------------------------------------------------------------------------------
BaixaSE1 -> função para baixar o SE1 posicionado
-----------------------------------------------------------------------------------
*/
Static Function BaixaSE1(cBanco, cAgencia, cNumCon, cChavSE1)

	Local lRet 		:= .F.
	Local _aBaixa 	:= {}
	Local dDtFin	:= GetMV("MV_DATAFIN")
	Local cBkpFunNam := FunName()

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .F.

	iif(ddatabase<dDtFin,PutMvPar("MV_DATAFIN",ddatabase),)

	BeginTran()

	_aBaixa := {;
		{"E1_FILIAL"    ,SE1->E1_FILIAL 		,Nil},;
		{"E1_PREFIXO"   ,SE1->E1_PREFIXO		,Nil},;
		{"E1_NUM"       ,SE1->E1_NUM			,Nil},;
		{"E1_PARCELA"   ,SE1->E1_PARCELA		,Nil},;
		{"E1_TIPO"      ,SE1->E1_TIPO			,Nil},;
		{"E1_CLIENTE" 	,SE1->E1_CLIENTE 		,Nil},;
		{"E1_LOJA" 		,SE1->E1_LOJA 			,Nil},;
		{"AUTMOTBX"     ,"DEB" /*"NOR" -> Motivo da Baixa*/,Nil},;
		{"AUTBANCO"     ,cBanco 				,Nil},;
		{"AUTAGENCIA"   ,cAgencia 				,Nil},;
		{"AUTCONTA"     ,cNumCon 				,Nil},;
		{"AUTDTBAIXA"   ,dDataBase				,Nil},;
		{"AUTDTCREDITO" ,dDataBase				,Nil},;
		{"AUTHIST"      ,"COMPENSACAO PDV"      ,Nil},;
		{"AUTJUROS"     ,0                      ,Nil,.T.},;
		{"AUTVALREC"    ,SE1->E1_SALDO			,Nil}}

	SetFunName("FINA070") //ADD Danilo, para ficar correto campo E5_ORIGEM (relatorios e rotinas conciliacao)
	MSExecAuto({|x,y| Fina070(x,y)}, _aBaixa, 3) //Baixa conta a receber
	SetFunName(cBkpFunNam)

	If lMsErroAuto
		DisarmTransaction()
		If !IsBlind()
			MostraErro()
		Else
			cErroExec := MostraErro("\temp")
			//Conout(" ============ ERRO =============")
			//Conout(cErroExec)
			cErroExec := ""
		EndIf
	EndIf
EndTran()

//verifico se o titulo foi incluido mesmo (as vezes mesmo lMsErroAuto sendo true, o titulo foi incluido)
SE1->(DbSetOrder(1))
If SE1->(DbSeek(cChavSE1)) .AND. SE1->E1_SALDO == 0
	lRet := .T.
EndIf

iif(ddatabase<dDtFin,PutMvPar("MV_DATAFIN",dDtFin),)

Return lRet

//--------------------------------------------------------------------------------------
//Cancela baixa do título posicionado
//--------------------------------------------------------------------------------------
Static Function CancBxSE1()

	Local lRet := .T.
	Local aFin070 := {}
	Local cChvE1 := SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO
	Local nBkpDBas := dDataBase

	if !empty(SE1->E1_BAIXA) .AND. dDatabase <> SE1->E1_BAIXA
		dDataBase := SE1->E1_BAIXA
	endif

	AADD( aFin070, {"E1_FILIAL"  , SE1->E1_FILIAL	, Nil})
	AADD( aFin070, {"E1_PREFIXO" , SE1->E1_PREFIXO	, Nil})
	AADD( aFin070, {"E1_NUM"     , SE1->E1_NUM 		, Nil})
	AADD( aFin070, {"E1_PARCELA" , SE1->E1_PARCELA	, Nil})
	AADD( aFin070, {"E1_TIPO"    , SE1->E1_TIPO		, Nil})

	//Assinatura de variáveis que controlarão a exclusão automática do título;
	lMsErroAuto := .F.
	lMsHelpAuto := .T.

	//rotina automática para exclusão da baixa do título;
	MSExecAuto({|x,y| Fina070(x,y)}, aFin070, 6)

	//Quando houver erros, exibí-los em tela;
	If lMsErroAuto
		MostraErro()
	EndIf

	dDataBase := nBkpDBas

	SE1->(DbSetOrder(1))
	If SE1->(DbSeek(cChvE1))
		If SE1->E1_SALDO == 0 //verifica se realmente foi cancelada a baixa
			lRet := .F.
		EndIf
	EndIf

Return lRet

//-------------------------------------------------------------------
// EXCLUI UM SE1
//-------------------------------------------------------------------
Static Function ExcSE1(cChaveCH)

	Local lRet := .T.
	Local aFin040 := {}
	Local cChavE1 := SE1->E1_FILIAL+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO

	//Assinatura de variáveis que controlarão a inserção automática da RA			;
		Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	AADD( aFin040, {"E1_FILIAL"  , SE1->E1_FILIAL  	,Nil})
	AADD( aFin040, {"E1_PREFIXO" , SE1->E1_PREFIXO 	,Nil})
	AADD( aFin040, {"E1_NUM"     , SE1->E1_NUM	   	,Nil})
	AADD( aFin040, {"E1_PARCELA" , SE1->E1_PARCELA	,Nil})
	AADD( aFin040, {"E1_TIPO"    , SE1->E1_TIPO  	,Nil})

	//Invocando rotina automática para exclusao 									;
		MSExecAuto({|x,y| Fina040(x,y)}, aFin040, 5)

	//Quando houver erros, exibí-los em tela										 ;
		If lMsErroAuto
		If !IsBlind()
			MostraErro()
		Else
			cErroExec := MostraErro("\temp")
			//Conout(" ============ ERRO =============")
			//Conout(cErroExec)
			cErroExec := ""
		EndIf
	EndIf

	SE1->(DbSetOrder(1))
	If SE1->(DbSeek(cChavE1)) //se encontrar o titulo.. é pq nao conseguiu excluir
		lRet := .F.
	Else

		//se nao deletou o cheque no padrão, força exclusao
		If !empty(cChaveCH)
			DbSelectArea("SEF")
			SEF->(DbSetOrder(3))
			If SEF->(DbSeek(xFilial("SEF")+ SE1->E1_PREFIXO + SE1->E1_NUM + SE1->E1_PARCELA + SE1->E1_TIPO ))
				RecLock("SEF",.F.)
				SEF->(DbDelete())
				SEF->(MsUnLock())
			EndIf
		EndIf

	EndIf

Return lRet
