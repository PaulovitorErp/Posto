#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} TPDVP001 (LJ7002)
Ponto de Entrada chamado depois da gravação de todos os dados
e da impressão do cupom fiscal na Venda Assistida e após o
processamento do Job LjGrvBatch(FRONT LOJA).

@param ParamIxb
Parâmetros:
Nome			Tipo			Descrição
ExpN1			Numérico		Contém o tipo de operação de gravação, sendo:
1 - orçamento
2 - venda
3 - pedido
ExpA2			Array of Record	Array de 1 dimensão contendo os dados da devolução na seguinte ordem:
1 - série da NF de devolução
2 - número da NF de devolução
3 - cliente
4 - loja do cliente
5 - tipo de operação (1 - troca; 2 - devolução)
ExpN3			Array of Record	Contém a origem da chamada da função, sendo:
1 = Genérica
2 = GRVBatch

@return Nenhum(nulo)
@author Totvs - Goias
/*/
User Function TPDVP001()

	Local nTipoOp 	:= ParamIxb[1]
	//Local aDevol    := ParamIxb[2]
	Local nOrigem 	:= ParamIxb[3] //Contém a origem da chamada da função, sendo: 1 = Genérica / 2 = GRVBatch

	Local lFisLivro 	:= SuperGetMV("MV_LJLVFIS",,1) == 2		// Utiliza novo conceito para geracao do SF3

	Local lMvPosto := SuperGetMv("MV_XPOSTO",.F.,.F.) //Habilita Posto de Combustível (Posto Inteligente).
	//Caso o Posto Inteligente não esteja habilitado não faz nada...
	If !lMvPosto
		Return
	EndIf

	//Conout("Entrou no fonte TPDVP001 - " + Time())

	//--------------------------------------------------------------------------------------------------
	//Processos a serem executados no GrvBatch
	//--------------------------------------------------------------------------------------------------
	//quando nota está vindo nOrigem == 2 -> GRVBatch
	If nOrigem == 2 .AND. !IsInCallStack("STIPosMain")

		//Conout("TPDVP001 origem GRVBatch - nOrigem == 2 .AND. !IsInCallStack(STIPosMain)")

		//tratamento para norma tecnica, nota acobertamento
		If SL1->(ColumnPos("L1_INDPRES")) > 0 .AND. empty(SL1->L1_INDPRES)
			RecLock("SL1",.F.)
				SL1->L1_INDPRES := '1'
			SL1->(MsUnLock())
		Endif

		//tratamento para gravacao de campos customizados na SE5
		GrvCpSE5()

		//tratamento do vale haver
		If SL1->L1_XTROCVL > 0
			U_TPDVE008(SL1->L1_XTROCVL) //ajusta o troco: remove da saida de caixa da SE5 e gera NCC do vale haver
		EndIf

		//tratamento para inclusao do motorista, a partir do campo CPF informado na venda
		If SL1->(FieldPos("L1_CGCMOTO")) > 0 .and. SL1->(FieldPos("L1_NOMMOTO")) > 0 .and. !Empty(SL1->L1_CGCMOTO) .AND. !empty(SL1->L1_NOMMOTO)
			AddMotoris(SL1->L1_CGCMOTO, SL1->L1_NOMMOTO)
		EndIf

		//ajuste necessario para a contabilização do troco
		if SuperGetMv("TP_MTPDOCT",,.T.)
			U_TPDVE012(SL1->L1_DOC,SL1->L1_SERIE)
		endif

		//atualiza as informações da SF2/SD2
		If FindFunction("U_UD2XVEND")
			U_UD2XVEND( SL1->L1_NUM )
		EndIf

		//DANILO: Tratamento para alterar status da requisição pré U57, usada na venda
		if SL1->L1_CREDITO > 0
			U_TRA028CR()
		endif
		//FIM DANILO U57

	EndIf

	//apos StMiniGrvBatch (LOJXFUNC) - Totvs PDV Mini-GravaBatch

	//Cálculo dos valores de ICMS recolhido anteriormente, considerando
	//as últimas entradas, fazendo a proporcionalidade dos valores das últimas entradas
	//em função da quantidade de saída
	If nTipoOp == 2 .and. nOrigem == 2 //.and. IsInCallStack("STIPosMain") comentado para forçar a execução do mesmo calculo na retaguarda
		If lFisLivro .AND. cPaisLoc == "BRA" ;
				.and. !SF2->(Eof())

			//tratativa do flag de autorização de NFE e NFCe
			RecLock('SF2',.F.)
				SF2->F2_FIMP := "S"
			SF2->(MsUnlock())

			LjGrvLog( "PE LJ7002 - Cálculo dos valores de ICMS recolhido anteriormente - L1_NUM: " + SL1->L1_NUM, "SF2->(Recno())", SF2->(Recno()) )

			//Atualizo SFT
			SFT->(dbSetOrder(1)) //FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL+FT_CLIEFOR+FT_LOJA+FT_ITEM+FT_PRODUTO
			cChave := xFilial("SFT")+"S"+SF2->F2_SERIE+SF2->F2_DOC+SF2->F2_CLIENTE+SF2->F2_LOJA
			If SFT->(MsSeek(cChave,.T.))
				Do While SFT->(!Eof()) .AND. cChave == SFT->FT_FILIAL+SFT->FT_TIPOMOV+SFT->FT_SERIE+SFT->FT_NFISCAL+SFT->FT_CLIEFOR+SFT->FT_LOJA

					aNfItem := xFisQryUEnt(SFT->FT_PRODUTO,SFT->FT_QUANT)
					If ValType( aNfItem ) == "A" .and. Len( aNfItem ) >= 7
						RecLock("SFT",.F.)
						If SFT->(FieldPos("FT_BSTANT")) > 0
							SFT->FT_BSTANT  := aNfItem[1]//IT_BSTANT
						EndIf
						If SFT->(FieldPos("FT_VSTANT")) > 0
							SFT->FT_VSTANT  := aNfItem[2]//IT_VSTANT
						EndIf
						If SFT->(FieldPos("FT_VICPRST")) > 0
							SFT->FT_VICPRST := aNfItem[3]//IT_VICPRST
						EndIf
						If SFT->(FieldPos("FT_PSTANT")) > 0
							SFT->FT_PSTANT  := aNfItem[4]//IT_PSTANT
						EndIf
						If SFT->(FieldPos("FT_BFCANTS")) > 0
							SFT->FT_BFCANTS := aNfItem[5]//IT_BFCANTS
						EndIf
						If SFT->(FieldPos("FT_PFCANTS")) > 0
							SFT->FT_PFCANTS := aNfItem[6]//IT_PFCANTS
						EndIf
						If SFT->(FieldPos("FT_VFCANTS")) > 0
							SFT->FT_VFCANTS := aNfItem[7]//IT_VFCANTS
						EndIf
						SFT->(MsUnLock())
					EndIf

					SFT->(dbSkip())
				EndDo
			EndIf

		EndIf
	EndIf

	//Conout("Saida do fonte TPDVP001 - " + Time())

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} xFisQryUEnt

Função que fará query na SD1 em busca das últimas aquisições de um determinado
produto, considerando a data, quantidade e método de busca enviados na funçao

@param cCodProd,   caracter, Código de Produto
@param nQtdeSai,   numérico, Quantidade do item da nota fiscal de saída
@param cMetodo,    caracter, Método de obter as últimas aquisições
@param dDataRefer, date    , Data de referência, para buscar as últimas entradas anteriores a esta data
@param cTpDb,      caracter, Tipo do banco de dados do ambiente
@param aNfItem,    array, Array com as informações do ANFITEM
@param aNfCab,    array, Array com as informações do ANFCAB
@param aSX6,      array, Array com o cacheamento dos parâmetros SX6

@author Erick Dias
@since 21/02/2019
@version 12.1.23
/*/
//-------------------------------------------------------------------
Static Function xFisQryUEnt(cCodProd, nQtdeSai)

	Local cWhere		:= ""
	Local cAliasQry		:= "SD1"
	Local nTotQtdeE		:= 0
	Local nQtdeRow		:= 0
	Local nValRet		:= 0
	Local nBasRet		:= 0
	Local nPerRet		:= 0
	Local nICMSSub		:= 0
	Local nBaseFcp		:= 0
	Local nPercFcp		:= 0
	Local nFcp		  	:= 0
	Local lDevCompra	:= .F.
	Local nQtdeSaldo	:= nQtdeSai
	Local nMult			:= 0
	Local dDataRefer    := Date()
	Local cMetodo		:= AllTrim(SuperGetMv("MV_ULTAQUI",,""))
	Local aNfItem 		:= Array(8)
	Local aNfREt 		:= Array(7)

	Local RI_PRODUTO			:= 1
	Local RI_ICMS_ANT_UNIT		:= 2
	Local RI_BASE_ANT_UNIT		:= 3
	Local RI_PERC_ANT_UNIT		:= 4
	Local RI_ICMS_SUBST_UNIT	:= 5
	Local RI_BASE_FCP_ANT_UNIT	:= 6
	Local RI_PERC_FCP_ANT_UNIT	:= 7
	Local RI_FCP_ANT_UNIT		:= 8

	If cMetodo == '1'
		//Para o primeiro método, deve-se considerar somente a última nota fiscal, por este motivo virá somente 1 quantidade de linha
		nQtdeRow	:= 1
	Elseif cMetodo == '2' .OR. cMetodo == '3'
		//Já para o segundo método, deve-se compor a média ponderada, e para isso estou limitando no máximo 50 linhas de retorno, por questões de performance.
		nQtdeRow	:= 50
	EndIF

//Inicializa as referências de ressarcimento com valores zerados
	aNfItem[RI_PRODUTO]		     	:= cCodProd
	aNfItem[RI_ICMS_ANT_UNIT]	 	:= nValRet
	aNfItem[RI_BASE_ANT_UNIT]	 	:= nBasRet
	aNfItem[RI_PERC_ANT_UNIT]	 	:= nPerRet
	aNfItem[RI_ICMS_SUBST_UNIT]	  	:= nICMSSub
	aNfItem[RI_BASE_FCP_ANT_UNIT]  	:= nBaseFcp
	aNfItem[RI_PERC_FCP_ANT_UNIT]  	:= nPercFcp
	aNfItem[RI_FCP_ANT_UNIT]		:= nFcp

	//Se não houver produto preenchido e método nada será feito
	If !Empty(cCodProd) .AND. !Empty(cMetodo) .AND. (nQtdeRow > 0)

		//Para filtrar a quantidade de linhas da query, para SQL e INFORMIX deve ser feito na seção do select com FIRST e TOP
		//Query para buscar as últimas aquisições
		cWhere  := "D1_FILIAL = '" + xFilial("SD1") + "' .AND. "
		cWhere  += "D1_COD = '" + cCodProd + "' .AND. "
		cWhere  += "DtoS(D1_DTDIGIT) <= '" + DtoS(dDataRefer) + "' .AND. "
		cWhere  += "D1_TES <> '   ' .AND. "
		cWhere  += "D1_NFORI = ' ' .AND. "
		cWhere  += "D1_SERIORI = ' ' .AND. "
		cWhere  += "!(D1_TIPO $ 'BDPIC') .AND. "
		cWhere  += "(D1_ICMNDES > 0 .OR. D1_VALANTI > 0 .OR. D1_ICMSRET > 0 ) .AND. "
		cWhere  += "(D1_QUANT <> D1_QTDEDEV)"

		//cWhere  += " Order by SD1.D1_DTDIGIT desc, SD1.D1_NUMSEQ desc " 6 -> D1_FILIAL+DTOS(D1_DTDIGIT)+D1_NUMSEQ

		// limpo os filtros da SD1
		(cAliasQry)->(DbClearFilter())

		// executo o filtro na SD1
		bCondicao 	:= "{|| " + cWhere + " }"
		(cAliasQry)->(DbSetFilter(&bCondicao,cWhere))
		(cAliasQry)->(DbGoTop())

		DbSelectArea(cAliasQry)
		(cAliasQry)->(DbSetOrder(6)) //D1_FILIAL+DTOS(D1_DTDIGIT)+D1_NUMSEQ
		// posiciono no ultimo registro
		(cAliasQry)->(DbGoBottom())

		//Laco da query
		Do While (cAliasQry)->(!Bof()) //!(cAliasQry)->(Eof())

			//Somente continuará se a quantidade for maiormaior que zero
			IF (cAliasQry)->D1_QUANT > 0

				nQtdeRow-- //diminui a quantidade notas fiscais utilizadas

				//Acumula quantidade de produtos da compra processada
				nTotQtdeE += (cAliasQry)->D1_QUANT

				If cMetodo == "3"
					Iif ( nQtdeSaldo > (cAliasQry)->D1_QUANT,  nMult := (cAliasQry)->D1_QUANT, 	nMult := nQtdeSaldo )
				EndIf
				//Verifica se foi digitado manualmente pelo usuário
				IF (cAliasQry)->D1_ICMNDES > 0
					nValRet	+= Iif(cMetodo == "3", (cAliasQry)->D1_ICMNDES / (cAliasQry)->D1_QUANT * nMult , (cAliasQry)->D1_ICMNDES)
					nBasRet	+= Iif(cMetodo == "3",(cAliasQry)->D1_BASNDES / (cAliasQry)->D1_QUANT * nMult , (cAliasQry)->D1_BASNDES)

					nPerRet	:= (cAliasQry)->D1_ALQNDES
					//Não estou considerando ICMS do substituto, pois neste caso o contribuonte é o segundo substituído em diante, e não tem o ICMS do substituto.

					//Verifica se é antecipação tributária
				ElseIF (cAliasQry)->D1_VALANTI > 0
					nValRet	+= Iif(cMetodo == "3" ,(cAliasQry)->D1_VALANTI / (cAliasQry)->D1_QUANT * nMult , (cAliasQry)->D1_VALANTI)
					nBasRet	+= Iif(cMetodo == "3" ,(cAliasQry)->D1_BRICMS / (cAliasQry)->D1_QUANT * nMult  , (cAliasQry)->D1_BRICMS )
					nPerRet	:= (cAliasQry)->D1_ALIQSOL
					//Não estou considerando ICMS do substituto, pois na antecipação o próprio cliente é substituto

					//Verifica se ICMS ST foi destacado na nota fiscal de entrada
				ElseIf (cAliasQry)->D1_ICMSRET > 0
					nValRet	 += Iif(cMetodo == "3" , (cAliasQry)->D1_ICMSRET / (cAliasQry)->D1_QUANT * nMult ,(cAliasQry)->D1_ICMSRET)
					nBasRet	 += Iif(cMetodo == "3" , (cAliasQry)->D1_BRICMS / (cAliasQry)->D1_QUANT * nMult ,(cAliasQry)->D1_BRICMS)
					nICMSSub += Iif(cMetodo == "3" , (cAliasQry)->D1_VALICM / (cAliasQry)->D1_QUANT * nMult ,(cAliasQry)->D1_VALICM)
					nPerRet	 := (cAliasQry)->D1_ALIQSOL
				EndIf

				//FECP
				If (cAliasQry)->D1_VFCPANT > 0 //FECP recolhido anteriormente
					nFcp		+= Iif(cMetodo == "3" , (cAliasQry)->D1_VFCPANT / (cAliasQry)->D1_QUANT * nMult ,(cAliasQry)->D1_VFCPANT)
					nBaseFcp	+= Iif(cMetodo == "3" , (cAliasQry)->D1_BFCPANT / (cAliasQry)->D1_QUANT * nMult ,(cAliasQry)->D1_BFCPANT)
					nPercFcp	:= (cAliasQry)->D1_AFCPANT

				ElseIf (cAliasQry)->D1_VFECPST > 0 //FECP ST tributadp
					nFcp		+= Iif(cMetodo == "3" , (cAliasQry)->D1_VFECPST / (cAliasQry)->D1_QUANT * nMult, (cAliasQry)->D1_VFECPST)
					nBaseFcp	+= Iif(cMetodo == "3" , (cAliasQry)->D1_BSFCPST / (cAliasQry)->D1_QUANT * nMult, (cAliasQry)->D1_BSFCPST)
					nPercFcp	:= Iif((cAliasQry)->D1_FCPAUX > 0 , (cAliasQry)->D1_FCPAUX ,(cAliasQry)->D1_ALFCPST )
				EndIF

				//Para o segundo método, preciso ver se a quantidade já foi suportada.
				//Se for devolução de compra também não precisarei passar para a próxima entrada, já que conseguimos determinar o item em questão.
				If (cMetodo == "2" .AND. nTotQtdeE >= nQtdeSai) .OR. lDevCompra
					//Se a quantidade foi suportada não preciso processar próxima nota de entrada
					Exit
				EndIF

				If nQtdeRow<=0
					//Se a quantidade de registros já foi atingida não processa a proxima nota de entrada
					Exit
				EndIf

				If nQtdeSai > (cAliasQry)->D1_QUANT .AND. cMetodo == "3"
					nQtdeSaldo -= (cAliasQry)->D1_QUANT
				EndIF
			EndIF

			(cAliasQry)->(DbSkip(-1))
		Enddo

		//Fecha o Alias antes de sair da função
		(cAliasQry)->(DbClearFilter())
		IF !lDevCompra
			dbSelectArea(cAliasQry)
			dbCloseArea()
		EndIF

		//Atualiza as referências com valores unitários
		aNfItem[RI_PRODUTO]		     	:= cCodProd
		aNfItem[RI_ICMS_ANT_UNIT]	 	:= Iif(cMetodo == "3",nValRet, nValRet / nTotQtdeE )
		aNfItem[RI_BASE_ANT_UNIT]	 	:= Iif(cMetodo == "3",nBasRet, nBasRet / nTotQtdeE )
		aNfItem[RI_PERC_ANT_UNIT]	 	:= nPerRet
		aNfItem[RI_ICMS_SUBST_UNIT]	 	:= Iif(cMetodo == "3",nICMSSub, nICMSSub / nTotQtdeE )
		aNfItem[RI_BASE_FCP_ANT_UNIT] 	:= Iif(cMetodo == "3",nBaseFcp, nBaseFcp / nTotQtdeE )
		aNfItem[RI_PERC_FCP_ANT_UNIT] 	:= nPercFcp
		aNfItem[RI_FCP_ANT_UNIT]		:= Iif(cMetodo == "3",nFcp, nFcp / nTotQtdeE )

	EndIf

	aNfREt := Array(7)
	aNfREt[1]  := Iif(cMetodo == "3", aNfItem[RI_BASE_ANT_UNIT], SFT->FT_QUANT * aNfItem[RI_BASE_ANT_UNIT] )
	aNfREt[2]  := Iif(cMetodo == "3", aNfItem[RI_ICMS_ANT_UNIT], SFT->FT_QUANT * aNfItem[RI_ICMS_ANT_UNIT] )
	aNfREt[3]  := Iif(cMetodo == "3", aNfItem[RI_ICMS_SUBST_UNIT], SFT->FT_QUANT * aNfItem[RI_ICMS_SUBST_UNIT] )
	aNfREt[4]  := aNfItem[RI_PERC_ANT_UNIT]
	aNfREt[5]  := Iif(cMetodo == "3", aNfItem[RI_BASE_FCP_ANT_UNIT], SFT->FT_QUANT * aNfItem[RI_BASE_FCP_ANT_UNIT] )
	aNfREt[6]  := aNfItem[RI_PERC_FCP_ANT_UNIT]
	aNfREt[7]  := Iif(cMetodo == "3", aNfItem[RI_FCP_ANT_UNIT], SFT->FT_QUANT * aNfItem[RI_FCP_ANT_UNIT] )

Return aNfREt


/*/{Protheus.doc} AddMotoris
Funcao para gravacao do motorista a partir CPF informado no cupom
@author Danilo Brito
@since 24/09/2018
@version 1.0
@return Nil
@param cCGCMot, CPF do Motorista
@param cNomeMot, nome do Motorista
@type function
/*/
Static Function AddMotoris(cCGCMot, cNomeMot)

	Local aArea := GetArea()
	Local aCampos := {}
	Local nOpc := 3 //inclusao
	Private lMsErroAuto := .F.

	if empty(cNomeMot)
		cNomeMot := "NAO INFORMADO"
	endif

	DbSelectArea("DA4")
	DA4->(DbSetOrder(3)) //DA4_FILIAL+DA4_CGC
	if DA4->(DbSeek(xFilial("DA4")+SubStr(cCGCMot,1,TamSX3("DA4_CGC")[1])))
		nOpc := 4 //alteracao
		aadd(aCampos, {"DA4_COD", DA4->DA4_COD } )
	endif

	aadd(aCampos, {"DA4_NOME"	, SubStr(cNomeMot,1,TamSX3("DA4_NOME")[1]) } )
	aadd(aCampos, {"DA4_NREDUZ"	, SubStr(cNomeMot,1,TamSX3("DA4_NREDUZ")[1]) } )
	aadd(aCampos, {"DA4_CGC"	, SubStr(cCGCMot,1,TamSX3("DA4_CGC")[1]) } )

	//chama a gravaçao execauto MVC
	lMsErroAuto := .F.
	FWMVCRotAuto(FWLoadModel("OMSA040"),"DA4",nOpc,{{"OMSA040_DA4",aCampos}},,.T.)

	RestArea(aArea)

Return

/*/{Protheus.doc} GrvCpSE5
Gravacao de campos customizados na SE5, a partir da SL1

@author thebr
@since 19/08/2019
@version 1.0
@return Nil
@type function
/*/
Static Function GrvCpSE5()

	Local aArea := GetArea()
	Local aAreaSE5 := SE5->(GetArea())

	//Conout("Entrou no fonte TPDVP001 - GrvCpSE5")

	SE5->(dbsetorder(18)) //I -> E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_BANCO+E5_MOEDA
	If SE5->(dbseek(xFilial("SE5")+SL1->(L1_SERIE+L1_DOC+L1_OPERADO)))
		While SE5->(!Eof()) .and. xFilial("SE5")+SL1->(L1_SERIE+L1_DOC+L1_OPERADO) == SE5->(E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_BANCO)

			//Conout( "PE LJ7002 - Chave SE5: " + SE5->(E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_BANCO) )

			RecLock("SE5",.F.)
			SE5->E5_NUMMOV  := SL1->L1_NUMMOV
			SE5->E5_XPDV 	:= SL1->L1_PDV
			SE5->E5_XESTAC 	:= SL1->L1_ESTACAO
			SE5->E5_XHORA 	:= SL1->L1_HORA
			SE5->E5_CLIFOR 	:= SL1->L1_CLIENTE
			SE5->E5_LOJA 	:= SL1->L1_LOJA
			SE5->(MsUnLock())

			SE5->(dbskip())
		EndDo
	EndIf

	RestArea(aAreaSE5)
	RestArea(aArea)

Return
