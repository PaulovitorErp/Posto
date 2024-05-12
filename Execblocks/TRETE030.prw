#include "protheus.ch"
#include "topconn.ch"
#include "tbiconn.ch"

Static cFImpBol := SuperGetMv("MV_XFUNBOL",.F.,"TRETR009") //fonte para impressao de boletos
Static cFImpFat := SuperGetMv("MV_XFUNFAT",.F.,"TRETE020") //fonte para impressao da fatura

/*/{Protheus.doc} TRETE030
Job Faturamento Automático
@author Maiki Perin
@since 06/08/2014
@version P11
@param Nao recebe parametros
@return nulo
/*/
User Function TRETE030(cParEmp,cParFil,cParalelo)

	Local cEmpAtu 		:= ""
	Local cFilAtu 		:= ""
	Local lFeriado

	Default cParalelo	:= "F"

	RpcSetType(3)
	RpcSetEnv(cParEmp,cParFil)

	Conout("############ INICIO DO JOB FATURAMENTO AUTOMATICO - ROTINA TRETE030 #############")
	Conout(">> DATA: "+ DToC(Date()) +" - HORA: " + Time())

	If cParalelo == "F" //Processamento sequencial

		cEmpAtu 	:= cEmpAnt
		cFilAtu 	:= cFilAnt

		DbSelectArea("SM0")
		SM0->(DbGoTop())
		SM0->(DbSeek(cEmpAtu+cFilAtu))

		While SM0->(!EOF()) .And. AllTrim(SM0->M0_CODIGO) == cParEmp

			If cFilAtu <> cParFil

				RpcClearEnv()
				RpcSetType(3)
				RpcSetEnv(cEmpAtu,cFilAtu)

				DbSelectArea("SM0")
				SM0->(DbSeek(cEmpAtu+cFilAtu))
			Endif

			lFeriado := RetFer()

			If !lFeriado //.And. cFilAnt == "0501"
				ExecFat()
			Else
				Conout("Hoje é feriado para a EMPRESA: "+ cEmpAnt +" - FILIAL: " + cFilAnt + ", baseado na tabela genérica 63, faturamento não executado.")
			Endif

			SM0->(DbSkip())

			cFilAtu := SM0->M0_CODFIL
		EndDo

	Else //Processamento paralelo

		lFeriado := RetFer()

		If !lFeriado //.And. cFilAnt == "0801"
			ExecFat()
		Else
			Conout("Hoje é feriado para a EMPRESA: "+ cEmpAnt +" - FILIAL: " + cFilAnt + ", baseado na tabela genérica 63, faturamento não executado.")
		Endif
	Endif

	Conout("############ FIM DO JOB FATURAMENTO AUTOMATICO - ROTINA TRETE030 #############")

	RpcClearEnv()

Return

/************************/
Static Function ExecFat()
/************************/

	Local cQry 			:= ""
	Local aReg			:= {}

	Local lAchou		:= .F.

	Local cNat			:= SuperGetMv( "MV_XNATFAT" , .F. , "OUTROS    ",)
	Local cImpostos		:= ""

	Local lFa280Qry		:= ExistBlock("FA280QRY")
	Local cQueryADD 	:= ""

	Local cTpFat		:= SuperGetMv("MV_XTPFTAU",,"NP/RP/CF/VLS/CTF")
	Local lConfCx		:= SuperGetMv("MV_XCONFCX",,.T.) //Exige conferência de caixa
	Local cSerieNF		:= SuperGetMv("MV_XSERFAT",.F.,"")
	//Local cSerVd		:= ""

	Local aCliente		:= {}

	Local lRestGrp		:= .F.
	Local lRestPrd		:= .F.
	Local lSepFpg		:= .F.
	Local lSepMot		:= .F.
	Local lSepOrd		:= .F.

	Local aGrpProd 		:= {}
	Local aProd			:= {}

	Local aEnvMail		:= {}

	Local aTit			:= {}
	Local aLinAux		:= {}

	Local aTmpCli 		:= {}
	Local aTmpSepFp		:= {}
	Local aTmpSepMt		:= {}
	Local aTmpSepOs		:= {}
	Local aTmpGrp		:= {}
	Local aTmpProd		:= {}

	Local nI
	Local nJ
	Local nK
	Local nL
	Local nM
	Local nX

	Local cGrpOri		:= ""
	Local cGrpDest		:= ""
	Local cProdOri		:= ""
	Local cProdDest		:= ""

	Local cNFRecu		:= SuperGetMv("MV_XNFRECU",.F.,"XPROTH/XCOPIA/XSEFAZ/XXML") //Tipos de recuperação de NF
	Local nVlrAcess := 0

	Local lFatNatOr		:= SuperGetMv("MV_XFTNATO",,.F.) //define se a fatura irá assuimir a mesma natureza dos titulos origem

	//Private aArqPDF		:= {}

	Private nPosFilial	:= U_TRE017CP(5,"nPosFilial")
	Private nPosFilOri	:= U_TRE017CP(5,"nPosFilOri")
	Private nPosTipo 	:= U_TRE017CP(5,"nPosTipo")
	Private nPosPrefixo	:= U_TRE017CP(5,"nPosPrefixo")
	Private nPosNumero	:= U_TRE017CP(5,"nPosNumero")
	Private nPosCliente	:= U_TRE017CP(5,"nPosCliente")
	Private nPosLoja	:= U_TRE017CP(5,"nPosLoja")
	Private nPosMotiv	:= U_TRE017CP(5,"nPosMotiv")
	Private nPosProdOs	:= U_TRE017CP(5,"nPosProdOs")
	Private nPosParcela	:= U_TRE017CP(5,"nPosParcela")
	Private nPosPortado	:= U_TRE017CP(5,"nPosPortado")
	Private nPosDeposit	:= U_TRE017CP(5,"nPosDeposit")
	Private nPosNConta	:= U_TRE017CP(5,"nPosNConta")
	Private nPosPlaca	:= U_TRE017CP(5,"nPosPlaca")
	Private nPosEmissao	:= U_TRE017CP(5,"nPosEmissao")
	Private nPosVencto	:= U_TRE017CP(5,"nPosVencto")
	Private nPosValor	:= U_TRE017CP(5,"nPosValor")
	Private nPosSaldo	:= U_TRE017CP(5,"nPosSaldo")
	Private nPosDescont	:= U_TRE017CP(5,"nPosDescont")
	Private nPosMulta	:= U_TRE017CP(5,"nPosMulta")
	Private nPosJuros	:= U_TRE017CP(5,"nPosJuros")
	Private nPosAcresc	:= U_TRE017CP(5,"nPosAcresc")
	Private nPosDecres	:= U_TRE017CP(5,"nPosDecres")
	Private nPosVlAcess	:= U_TRE017CP(5,"nPosVlAcess")
	Private nPosRecno	:= U_TRE017CP(5,"nPosRecno")
	Private nPosNCFret	:= U_TRE017CP(5,"nPosNCFret")
	Private nPosNsuTef	:= U_TRE017CP(5,"nPosNsuTef")
	Private nPosDocTef	:= U_TRE017CP(5,"nPosDocTef")
	Private nPosCartAu	:= U_TRE017CP(5,"nPosCartAu")

	Conout(">> EMPRESA: "+ cEmpAnt +" - FILIAL: " + cFilAnt)
	Conout(">> SELECIONANDO REGISTROS...")

	cImpostos := Fa280VerImp(cNat)

	If Select("QRYFAT") > 0
		QRYFAT->(DbCloseArea())
	Endif

	cQry := "SELECT SE1.E1_FILIAL,"
	cQry += CRLF + " SE1.E1_FILORIG,"
	cQry += CRLF + " SE1.E1_TIPO,"
	cQry += CRLF + " SE1.E1_PREFIXO,"
	cQry += CRLF + " SE1.E1_NUM,"
	cQry += CRLF + " SE1.E1_PARCELA,"
	cQry += CRLF + " SE1.E1_NATUREZ,"
	cQry += CRLF + " SE1.E1_PORTADO,"
	cQry += CRLF + " SE1.E1_AGEDEP,"
	cQry += CRLF + " SE1.E1_CONTA,"
	cQry += CRLF + " SE1.E1_XPLACA,"
	cQry += CRLF + " SE1.E1_CLIENTE,"
	cQry += CRLF + " SE1.E1_LOJA,"
	cQry += CRLF + " SE1.E1_EMISSAO,"
	cQry += CRLF + " SE1.E1_VENCTO,"
	cQry += CRLF + " SE1.E1_VALOR,"
	cQry += CRLF + " SE1.E1_SALDO,"
	cQry += CRLF + " SE1.E1_DESCONT,"
	cQry += CRLF + " SE1.E1_MULTA,"
	cQry += CRLF + " SE1.E1_JUROS,"
	cQry += CRLF + " SE1.E1_ACRESC,"
	cQry += CRLF + " SE1.E1_DECRESC,"
	cQry += CRLF + " SE1.R_E_C_N_O_ AS RECNO,"
	cQry += CRLF + " SF2.F2_DOC,"
	cQry += CRLF + " SF2.F2_SERIE,"
	cQry += CRLF + " SF2.F2_PDV,"
	cQry += CRLF + " U57.U57_MOTIVO,"
	if SE1->(FieldPos("E1_XPRDOS")) > 0
		cQry += CRLF + " SE1.E1_XPRDOS,"
	endif
	cQry += CRLF + " SE1.E1_VLRREAL,"
	cQry += CRLF + " SE1.E1_FATURA,"
	cQry += CRLF + " SE1.E1_NOMCLI,"
	cQry += CRLF + " SE1.E1_NUMCART,"
	cQry += CRLF + " SE1.E1_NSUTEF,"
	cQry += CRLF + " SE1.E1_DOCTEF,"
	cQry += CRLF + " SE1.E1_CARTAUT,"

	//DANILO: Regra que verifica se tem devolucao, trazido para melhorar performance.
	cQry += CRLF + " (SELECT COUNT(*)  "
	cQry += CRLF + " FROM "+RetSqlName("SD1")+" SD1  "
	cQry += CRLF + " WHERE SD1.D_E_L_E_T_	= ' '  "
	cQry += CRLF + " 	AND SD1.D1_FILIAL 	= SE1.E1_FILIAL  "
	cQry += CRLF + " 	AND SD1.D1_TIPO		= 'D'  "
	cQry += CRLF + " 	AND SD1.D1_NFORI	= SE1.E1_NUM  "
	cQry += CRLF + " 	AND SD1.D1_SERIORI	= SE1.E1_PREFIXO  "
	cQry += CRLF + " 	AND SD1.D1_FORNECE	= SE1.E1_CLIENTE  "
	cQry += CRLF + " 	AND SD1.D1_LOJA		= SE1.E1_LOJA  "
	cQry += CRLF + " ) AS QTDDEVOL,  "

	cQry += CRLF + " (CASE WHEN SE1.E1_TIPO='NP ' THEN '1'" //Nota a prazo
	cQry += CRLF + " 		WHEN SE1.E1_TIPO='VLS' THEN '2'" //Vale serviço
	cQry += CRLF + " 		WHEN SE1.E1_TIPO='RP ' THEN '3'" //Requisição
	cQry += CRLF + " 		WHEN SE1.E1_TIPO='CF ' THEN '4'" //Carta frete
	cQry += CRLF + " 		ELSE '5'" //Demais tipos
	cQry += CRLF + "  END) AS ORDEM_TP,"

	cQry += CRLF + " SE4.E4_DESCRI,"
	cQry += CRLF + " UF6.UF6_DESC,"
	cQry += CRLF + " SL1.L1_DOC,"
	cQry += CRLF + " SL1.L1_SITUA,"
	cQry += CRLF + " SL1.L1_STATUS"

	cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1 	LEFT JOIN "+RetSqlName("SF2")+" SF2 	ON SE1.E1_PREFIXO	= SF2.F2_SERIE"
	cQry += CRLF + " 										 									AND SE1.E1_NUM 		= SF2.F2_DOC"
	cQry += CRLF + " 										 									AND SE1.E1_CLIENTE 	= SF2.F2_CLIENTE"
	cQry += CRLF + " 										 									AND SE1.E1_LOJA 	= SF2.F2_LOJA"
	cQry += CRLF + "																			AND SF2.D_E_L_E_T_ = ' '"
	cQry += CRLF + " 																			AND SF2.F2_FILIAL	= '"+xFilial("SF2")+"'"
	If !Empty(cSerieNF)
		cQry += CRLF + " 																		AND SF2.F2_SERIE 	IN "+FormatIn(cSerieNF,";")
	Endif

	cQry += CRLF + " 									LEFT JOIN "+RetSqlName("U88")+" U88 	ON 	SE1.E1_CLIENTE	= U88.U88_CLIENT"
	cQry += CRLF + " 																			AND SE1.E1_LOJA		= U88.U88_LOJA"
	cQry += CRLF + " 																			AND SE1.E1_TIPO		= U88.U88_FORMAP"
	cQry += CRLF + " 																			AND U88.D_E_L_E_T_ = ' '"
	cQry += CRLF + " 																			AND U88.U88_FILIAL	= '"+xFilial("U88")+"'"

	cQry += CRLF + " 									INNER JOIN "+RetSqlName("SA1")+" SA1	ON SE1.E1_CLIENTE	= SA1.A1_COD"
	cQry += CRLF + " 																			AND SE1.E1_LOJA		= SA1.A1_LOJA"
	cQry += CRLF + " 																			AND SA1.D_E_L_E_T_ = ' '"
	cQry += CRLF + " 																			AND SA1.A1_FILIAL	= '"+xFilial("SA1")+"'"

	cQry += CRLF + " 									LEFT JOIN "+RetSqlName("UF6")+" UF6		ON SA1.A1_XCLASSE	= UF6.UF6_CODIGO"
	cQry += CRLF + " 																			AND UF6.D_E_L_E_T_ = ' '"
	cQry += CRLF + " 																			AND UF6.UF6_FILIAL	= '"+xFilial("UF6")+"'"

	cQry += CRLF + " 									LEFT JOIN "+RetSqlName("SE4")+" SE4		ON SE1.E1_XCOND		= SE4.E4_CODIGO"
	cQry += CRLF + " 																			AND SE4.D_E_L_E_T_ = ' '"
	cQry += CRLF + " 																			AND SE4.E4_FILIAL	= '"+xFilial("SE4")+"'"

	cQry += CRLF + " 									LEFT JOIN "+RetSqlName("SL1")+" SL1 	ON SE1.E1_PREFIXO	= SL1.L1_SERIE"
	cQry += CRLF + " 										 									AND SE1.E1_NUM 		= SL1.L1_DOC"
	cQry += CRLF + " 										 									AND SE1.E1_CLIENTE 	= SL1.L1_CLIENTE"
	cQry += CRLF + " 										 									AND SE1.E1_LOJA 	= SL1.L1_LOJA"
	cQry += CRLF + "																			AND SL1.D_E_L_E_T_ = ' '"
	cQry += CRLF + " 																			AND SL1.L1_FILIAL	= '"+xFilial("SL1")+"'"

	cQry += CRLF + " 									LEFT JOIN "+RetSqlName("U57")+" U57 	ON SE1.E1_XCODBAR	= U57.U57_PREFIX+U57.U57_CODIGO+U57.U57_PARCEL"
	cQry += CRLF + "																			AND U57.D_E_L_E_T_ = ' '"
	cQry += CRLF + " 																			AND U57.U57_FILIAL	= '"+xFilial("U57")+"'"

	cQry += CRLF + " WHERE SE1.D_E_L_E_T_ = ' '"
	cQry += CRLF + " AND SE1.E1_FILIAL		= '"+xFilial("SE1")+"'"
	cQry += CRLF + " AND SE1.E1_XDTFATU	< '"+DToS(dDataBase)+"'" //Montagem da fatura agendada para a data anterior a data atual
	cQry += CRLF + " AND SE1.E1_PREFIXO	<> 'IMP'" //Exclui os títulos importados do EmSys
	cQry += CRLF + " AND SE1.E1_TIPO		<> 'NCC'"
	cQry += CRLF + " AND SE1.E1_SALDO		> 0"
	cQry += CRLF + " AND (SF2.F2_ESPECIE	= 'CF   ' OR SF2.F2_ESPECIE	= 'NFCE ' OR SF2.F2_ESPECIE	= 'SPED ' OR SF2.F2_ESPECIE IS NULL)"

//Filtra tipos de convenios
	cQry += CRLF + " AND SE1.E1_TIPO		IN "+FormatIN(cTpFat,"/")+""

/****************************************************/
//Abaixo condições em conformidade com o fonte padrão
/****************************************************/

	cQry += CRLF + " AND SE1.E1_SITUACA 	IN ('0','F','G')" //Carteira, Carteira Protesto e Carteira Acordo
	cQry += CRLF + " AND SE1.E1_TIPO 		NOT IN "+FormatIN(MVRECANT+MVPROVIS,,3) //RA+PR

//Filtra para nao exibir os tx's
	cQry += CRLF + " AND SE1.E1_TIPO 		NOT IN "+FormatIN(cImpostos,,3)

//Verifica integracao com PMS e nao permite FATURAR titulos que tenham solicitacoes
//de transferencias em aberto.
	cQry += CRLF + " AND SE1.E1_NUMSOL		= ' '"

//Condicao para omitir os titulos de abatimento que tenham o titulo principal em bordero
	cQry += CRLF + " AND SE1.R_E_C_N_O_ NOT IN( "
	cQry += CRLF + " SELECT SE1A.R_E_C_N_O_ "
	cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1A "
	cQry += CRLF + " WHERE "
	cQry += CRLF + " SE1A.E1_FILIAL 	= SE1.E1_FILIAL AND "
	cQry += CRLF + " SE1A.E1_NUM 		= SE1.E1_NUM AND "
	cQry += CRLF + " SE1A.E1_PREFIXO 	= SE1.E1_PREFIXO AND "
	cQry += CRLF + " SE1A.E1_PARCELA 	= SE1.E1_PARCELA AND "
	cQry += CRLF + " SE1A.E1_TIPO 		IN "+FormatIN(MVABATIM,"|")+" AND " //AB-|FB-|FC-|FU-|IR-|IN-|IS-|PI-|CF-|CS-|FE-|IV-
	cQry += CRLF + " SE1A.E1_SITUACA 	NOT IN ('0','F','G') AND "
	cQry += CRLF + " SE1A.D_E_L_E_T_ 	= ' ' )"

//Condicao para evitar o título constar em mais de uma fatura
	cQry += CRLF + " AND SE1.R_E_C_N_O_ NOT IN( "
	cQry += CRLF + " SELECT SE1A.R_E_C_N_O_ "
	cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1A INNER JOIN "+RetSqlName("FI7")+" FI7 ON 	SE1A.E1_FILIAL		= FI7.FI7_FILIAL"
	cQry += CRLF + " 																			AND SE1A.E1_PREFIXO = FI7.FI7_PRFORI"
	cQry += CRLF + " 																			AND SE1A.E1_NUM 	= FI7.FI7_NUMORI"
	cQry += CRLF + " 																			AND SE1A.E1_PARCELA = FI7.FI7_PARORI"
	cQry += CRLF + " 																			AND SE1A.E1_TIPO 	= FI7.FI7_TIPORI"
	cQry += CRLF + " 																			AND SE1A.E1_CLIENTE = FI7.FI7_CLIORI"
	cQry += CRLF + " 																			AND SE1A.E1_LOJA 	= FI7.FI7_LOJORI"
	cQry += CRLF + " 																			AND SE1A.D_E_L_E_T_ = FI7.D_E_L_E_T_"
	cQry += CRLF + " WHERE "
	cQry += CRLF + " SE1A.E1_FILIAL 	= SE1.E1_FILIAL AND "
	cQry += CRLF + " SE1A.E1_NUM 		= SE1.E1_NUM AND "
	cQry += CRLF + " SE1A.E1_PREFIXO 	= SE1.E1_PREFIXO AND "
	cQry += CRLF + " SE1A.E1_PARCELA 	= SE1.E1_PARCELA AND "
	cQry += CRLF + " SE1A.E1_TIPO	 	= SE1.E1_TIPO AND "
	cQry += CRLF + " SE1A.D_E_L_E_T_ 	= ' ' )"

//Template GEM - nao podem ser faturados os titulos do GEM
	If HasTemplate("LOT")
		cQry += CRLF + " AND SE1.E1_NCONTR = ' '"
	EndIf

// Permite a inclusão de uma condicao adicional para a Query
// Esta condicao obrigatoriamente devera ser tratada em um AND ()
// para nao alterar as regras basicas da mesma.
	If lFa280Qry

		cQueryADD := ExecBlock("FA280QRY",.F.,.F.)

		If ValType(cQueryADD) == "C"
			cQry += CRLF + " AND (" + cQueryADD + ")"
		Endif
	Endif
/*****************************************************/
//fim das condições em conformidade com o fonte padrão
/*****************************************************/

	cQry += CRLF + " ORDER BY 31,30,3,4,5"

	cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\TRETE030.txt",cQry)
	TcQuery cQry NEW Alias "QRYFAT"

	DbSelectArea("U88")
	U88->(DbSetOrder(1)) //U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA
	U88->(DbGoTop())

	DbSelectArea("SA1")
	SA1->(dbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
	SA1->(DbGoTop())

	DbSelectArea("SB1")
	SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD
	SB1->(DbGoTop())

	DbSelectArea("SD2")
	SD2->(DbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	SD2->(DbGoTop())

	If QRYFAT->(!EOF())

		While QRYFAT->(!EOF())

			//Valida se o título não consta em liquidação
			/*DANILO: COMENTADO, POIS JA TEM O FILTRO NA QRY PRINCIPAL
			If U_TRETE30A(QRYFAT->E1_PREFIXO,QRYFAT->E1_NUM,QRYFAT->E1_PARCELA,QRYFAT->E1_TIPO,QRYFAT->E1_CLIENTE,QRYFAT->E1_LOJA)
				QRYFAT->(DbSkip())
				Loop
			Endif */

			If U88->(DbSeek(xFilial("U88")+"FT"+Space(6 - Len("FT"))+QRYFAT->E1_CLIENTE+QRYFAT->E1_LOJA)) // Compartilhado

				If !cFilAnt $ U88->U88_FILAUT //Filial não autorizada
					QRYFAT->(DbSkip())
					Loop
				Endif

				If U88->U88_FATAUT == "N" //Não fatura automaticamente
					QRYFAT->(DbSkip())
					Loop
				Endif
			Else
				AAdd(aEnvMail,{QRYFAT->E1_FILIAL,QRYFAT->E1_CLIENTE,QRYFAT->E1_LOJA,QRYFAT->E1_PREFIXO,QRYFAT->E1_NUM,QRYFAT->E1_PARCELA,;
					QRYFAT->E1_TIPO,QRYFAT->E1_VALOR,QRYFAT->E4_DESCRI,QRYFAT->UF6_DESC})
				QRYFAT->(dbSkip())
				Loop
			Endif

			//Envia e-mail caso o L1_SITUA seja diferente de "OK"
			If !Empty(QRYFAT->L1_DOC) .And. QRYFAT->L1_SITUA <> "OK"
				AAdd(aEnvMail,{QRYFAT->E1_FILIAL,QRYFAT->E1_CLIENTE,QRYFAT->E1_LOJA,QRYFAT->E1_PREFIXO,QRYFAT->E1_NUM,QRYFAT->E1_PARCELA,;
					QRYFAT->E1_TIPO,QRYFAT->E1_VALOR,QRYFAT->E4_DESCRI,"L1_SITUA = "+QRYFAT->L1_SITUA+" <> 'OK'"})
				QRYFAT->(dbSkip())
				Loop
			Endif

			//Envia e-mail caso de nota recuperada pela rotina MONITOR
			If QRYFAT->L1_STATUS $ cNFRecu
				AAdd(aEnvMail,{QRYFAT->E1_FILIAL,QRYFAT->E1_CLIENTE,QRYFAT->E1_LOJA,QRYFAT->E1_PREFIXO,QRYFAT->E1_NUM,QRYFAT->E1_PARCELA,;
					QRYFAT->E1_TIPO,QRYFAT->E1_VALOR,QRYFAT->E4_DESCRI,"NF RECUPERADA"})
				QRYFAT->(dbSkip())
				Loop
			Endif

			//Somente séries definidas
			/* DANILO: comentado, pois ja existe o filtro na query
			cSerVd := RetSerVd(QRYFAT->E1_NUM,QRYFAT->E1_PREFIXO,QRYFAT->E1_CLIENTE,QRYFAT->E1_LOJA)
			If !Empty(cSerVd)
				If !AllTrim(cSerVd) $ cSerieNF
					QRYFAT->(dbSkip())
					Loop
				Endif
			Endif
			*/

			//Conferência de caixa habilitada
			If lConfCx
				If PesqCxAbe(QRYFAT->RECNO)
					QRYFAT->(dbSkip())
					Loop
				Endif
			Endif

			//Desconsidera caso conste numa Nota de Devolução
			//DANILO: levado busca devolucao para query principal, para melhorar performance
			//If TemDev(QRYFAT->E1_FILIAL,QRYFAT->E1_NUM,QRYFAT->E1_PREFIXO,QRYFAT->E1_CLIENTE,QRYFAT->E1_LOJA)
			If QRYFAT->QTDDEVOL > 0
				QRYFAT->(dbSkip())
				Loop
			Endif

			SE1->(DbGoTo(QRYFAT->RECNO))
			nVlrAcess := U_UFValAcess(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA,SE1->E1_NATUREZ, Iif(Empty(SE1->E1_BAIXA),.F.,.T.),"","R",dDataBase,,SE1->E1_MOEDA,1/*nMoeda*/,SE1->E1_TXMOEDA)

			aLinAux := U_TRE017CP(3)
			aLinAux[1] := .T. //mark
			aLinAux[nPosFilial] := QRYFAT->E1_FILIAL
			if len(cFilAnt) <> len(AlltriM(xFilial("SE1")))
				aLinAux[nPosFilOri] := QRYFAT->E1_FILORIG
			endif
			aLinAux[nPosTipo] := QRYFAT->E1_TIPO
			aLinAux[nPosPrefixo] := QRYFAT->E1_PREFIXO
			aLinAux[nPosNumero] := QRYFAT->E1_NUM
			aLinAux[nPosParcela] := QRYFAT->E1_PARCELA
			aLinAux[nPosPortado] := QRYFAT->E1_PORTADO
			aLinAux[nPosDeposit] := QRYFAT->E1_AGEDEP
			aLinAux[nPosNConta] := QRYFAT->E1_CONTA
			aLinAux[nPosPlaca] := Transform(QRYFAT->E1_XPLACA,"@!R NNN-9N99")
			aLinAux[nPosCliente] := QRYFAT->E1_CLIENTE
			aLinAux[nPosLoja] := QRYFAT->E1_LOJA
			aLinAux[nPosEmissao] := DToC(SToD(QRYFAT->E1_EMISSAO))
			aLinAux[nPosVencto] := DToC(SToD(QRYFAT->E1_VENCTO))
			aLinAux[nPosValor] := Transform(IIF(QRYFAT->E1_VLRREAL > 0 .And. QRYFAT->E1_VLRREAL <> QRYFAT->E1_VALOR,QRYFAT->E1_VLRREAL,QRYFAT->E1_VALOR),"@E 9,999,999,999,999.99")
			aLinAux[nPosSaldo] := Transform(QRYFAT->E1_SALDO,"@E 9,999,999,999,999.99")
			aLinAux[nPosDescont] := Transform(QRYFAT->E1_DESCONT,"@E 9,999,999,999,999.99")
			aLinAux[nPosMulta] := Transform(QRYFAT->E1_MULTA,"@E 9,999,999,999,999.99")
			aLinAux[nPosJuros] := Transform(QRYFAT->E1_JUROS,"@E 9,999,999,999,999.99")
			aLinAux[nPosAcresc] := Transform(QRYFAT->E1_ACRESC,"@E 9,999,999,999,999.99")
			aLinAux[nPosDecres] := Transform(QRYFAT->E1_DECRESC,"@E 9,999,999,999,999.99")
			aLinAux[nPosVlAcess] := Transform(nVlrAcess,"@E 9,999,999,999,999.99")
			aLinAux[nPosRecno] := QRYFAT->RECNO
			aLinAux[nPosMotiv] := QRYFAT->U57_MOTIVO
			aLinAux[nPosProdOs] := QRYFAT->E1_XPRDOS
			aLinAux[nPosNCFret] := QRYFAT->E1_NUMCART
			aLinAux[nPosNsuTef] := QRYFAT->E1_NSUTEF
			aLinAux[nPosDocTef] := QRYFAT->E1_DOCTEF
			aLinAux[nPosCartAu] := QRYFAT->E1_CARTAUT

			AAdd(aReg, aLinAux)

			QRYFAT->(DbSkip())
		EndDo
	Endif

	If Len(aEnvMail) > 0
		EnvMail(aEnvMail)
	Endif

	Conout(">> "+cValToChar(Len(aReg))+" TITULOS SELECIONADOS")

	If Len(aReg) > 0

		Conout(">> INDIVIDUALIZANDO TITULOS...")

		For nI := 1 To Len(aReg)

			lRestGrp	:= .F.
			lRestPrd	:= .F.
			lSepFpg		:= .F.
			lSepMot		:= .F.
			lSepOrd		:= .F.

			aGrpProd	:= {}
			aProd		:= {}

			//Individualiza clientes
			If Len(aCliente) > 0
				If aScan(aCliente,{|x| x[1] == aReg[nI][nPosCliente] .And. x[2] == aReg[nI][nPosLoja]}) == 0
					AAdd(aCliente,{aReg[nI][nPosCliente],aReg[nI][nPosLoja]})
				Endif
			Else
				AAdd(aCliente,{aReg[nI][nPosCliente],aReg[nI][nPosLoja]})
			Endif

			//Características de Faturamento
			SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
			SA1->(DbGoTop())

			If SA1->(DbSeek(xFilial("SA1")+aReg[nI][nPosCliente]+aReg[nI][nPosLoja]))

				//Validação quanto a restrição de Grupos de Produto/Produtos
				If SA1->(FieldPos("A1_XNSEPAR")) > 0 .And. !Empty(SA1->A1_XRESTGP) .And. SA1->A1_XNSEPAR <> "S" //Possui restrição e não desconsidera a restrição para separação de faturas
					aGrpProd := StrTokArr(AllTrim(SA1->A1_XRESTGP),"/")
				Endif

				If SA1->(FieldPos("A1_XNSEPAR")) > 0 .And. !Empty(SA1->A1_XRESTPR) .And. SA1->A1_XNSEPAR <> "S" //Possui restrição e não desconsidera a restrição para separação de faturas
					aProd := StrTokArr(AllTrim(SA1->A1_XRESTPR),"/")
				Endif

				//Verifica Separações
				if lFatNatOr
                    lSepFpg := .T.
                else
					If SA1->A1_XSEPFPG == "S" //Individualiza fatura por forma de pagamento
						lSepFpg := .T.
					Else
						lSepFpg := .F.
					Endif
				endif
				
				If SA1->A1_XSEPMOT == "S" //Individualiza fatura por Motivo de saque
					lSepMot := .T.
				Else
					lSepMot := .F.
				Endif

				If SA1->A1_XSEPORD == "S" //Individualiza fatura por Ordem de serviço
					lSepOrd := .T.
				Else
					lSepOrd := .F.
				Endif
			Endif

			//Restrição quanto ao Grupo de Produto 
			if !empty(aGrpProd)
				SD2->(DbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
				SD2->(DbGoTop())

				SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD
				SB1->(DbGoTop())

				If SD2->(DbSeek(aReg[nI][nPosFilial]+aReg[nI][nPosNumero]+aReg[nI][nPosPrefixo]+aReg[nI][nPosCliente]+aReg[nI][nPosLoja])) //Exclusivo

					While SD2->(!EOF()) .And. SD2->D2_FILIAL == aReg[nI][nPosFilial] .And. SD2->D2_DOC == aReg[nI][nPosNumero] .And.;
							SD2->D2_SERIE == aReg[nI][nPosPrefixo] .And. SD2->D2_CLIENTE == aReg[nI][nPosCliente] .And. SD2->D2_LOJA == aReg[nI][nPosLoja]

						If SB1->(DbSeek(xFilial("SB1")+SD2->D2_COD)) //Compartilhado
							If aScan(aGrpProd,{|x| x == SB1->B1_GRUPO}) > 0
								lRestGrp := .T.
								Exit
							Endif
						Endif

						SD2->(DbSkip())
					EndDo
				Endif
			endif

			//Restrição quanto ao Produto 
			if !empty(aProd)
				SD2->(DbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
				SD2->(DbGoTop())
				If SD2->(DbSeek(aReg[nI][nPosFilial]+aReg[nI][nPosNumero]+aReg[nI][nPosPrefixo]+aReg[nI][nPosCliente]+aReg[nI][nPosLoja])) //Exclusivo

					While SD2->(!EOF()) .And. SD2->D2_FILIAL == aReg[nI][nPosFilial] .And. SD2->D2_DOC == aReg[nI][nPosNumero] .And.;
							SD2->D2_SERIE == aReg[nI][nPosPrefixo] .And. SD2->D2_CLIENTE == aReg[nI][nPosCliente] .And. SD2->D2_LOJA == aReg[nI][nPosLoja]

						If aScan(aProd,{|x| AllTrim(x) == AllTrim(SD2->D2_COD)}) > 0
							lRestPrd := .T.
							Exit
						Endif

						SD2->(DbSkip())
					EndDo
				Endif
			endif

			lSepMot := lSepMot .And. !IfVaziaS({aReg[nI]}) //Separa [Motivo de Saque] e possui informação de saque
			lSepOrd := lSepOrd .And. !IfVaziaO({aReg[nI]}) //Separa [Ordem de Serviço] e possui ordem de serviço
			lRestGrp := lRestGrp .And. !RetRpVls({aReg[nI]}) //Há restrição por [Grupo de Produto] e não se trata de um agrupamento de requisições ou vale
			lRestPrd := lRestPrd .And. !RetRpVls({aReg[nI]}) //Há restrição por [Produto] e não se trata de um agrupamento de requisições ou vale

			AAdd(aTit,{aReg[nI],;
				lSepFpg,;  //Separação por [Forma de Pagamento]
			lSepMot,;  //Separação por [Motivo de Saque]
			lSepOrd,;  //Separação por [Ordem de Serviço]
			lRestGrp,; //Restrição por [Grupo de Produto]
			lRestPrd}) //Restrição por [Produto]

		Next nI

		Conout(">> TITULOS INDIVIDUALIZADOS")

		For nI := 1 To Len(aCliente)

			aTmpCli 	:= {}
			aTmpSepFp	:= {}
			aTmpSepMt	:= {}
			aTmpSepOs	:= {}
			aTmpGrp		:= {}
			aTmpProd	:= {}

			Conout("CLIENTE: " + AllTrim(aCliente[nI][1]) + "/" + AllTrim(aCliente[nI][2]) + " - FILIAL: " + cFilAnt)

			//Agrupa os títulos por cliente
			For nJ := 1 To Len(aTit)

				If aCliente[nI][1] == aTit[nJ][1][nPosCliente] .And. aCliente[nI][2] == aTit[nJ][1][nPosLoja]

					If Len(aTmpCli) > 0

						lAchou :=  .F.

						For nK := 1 To Len(aTmpCli)

							For nL := 1 To Len(aTmpCli[nK][1])

								If aCliente[nI][1] == aTmpCli[nK][1][nL][nPosCliente] .And. aCliente[nI][2] == aTmpCli[nK][1][nL][nPosLoja] ;
										.And. aTmpCli[nK][2] == aTit[nJ][2] ; //lSepFpg
									.And. aTmpCli[nK][3] == aTit[nJ][3] ; //lSepMot
									.And. aTmpCli[nK][4] == aTit[nJ][4] ; //lSepOrd
									.And. aTmpCli[nK][5] == aTit[nJ][5] ; //lRestGrp
									.And. aTmpCli[nK][6] == aTit[nJ][6]	  //lRestPrd

									lAchou := .T.
									AAdd(aTmpCli[nK][1],aTit[nJ][1])
									Exit
								Endif
							Next nL

							If lAchou
								Exit
							Endif
						Next nK

						If !lAchou

							AAdd(aTmpCli,{{aTit[nJ][1]},aTit[nJ][2],aTit[nJ][3],aTit[nJ][4],aTit[nJ][5],aTit[nJ][6]})
						Endif
					Else
						AAdd(aTmpCli,{{aTit[nJ][1]},aTit[nJ][2],aTit[nJ][3],aTit[nJ][4],aTit[nJ][5],aTit[nJ][6]})
					Endif
				Endif
			Next nJ

			//Não há títulos relacionados ao cliente posicionado
			If Len(aTmpCli) == 0
				Loop
			Endif

			//Verifica se há separação por forma de pagamento
			For nJ := 1 To Len(aTmpCli)

				If aTmpCli[nJ][2] //Separa forma de pagamento

					For nK := 1 To Len(aTmpCli[nJ][1])

						If Len(aTmpSepFp) > 0

							lAchou :=  .F.

							For nL := 1 To Len(aTmpSepFp)

								For nM := 1 To Len(aTmpSepFp[nL][1])

									If aTmpSepFp[nL][1][nM][nPosTipo] == aTmpCli[nJ][1][nK][nPosTipo];
											.And. aTmpSepFp[nL][2] == aTmpCli[nJ][2] ; //lSepFpg
										.And. aTmpSepFp[nL][3] == aTmpCli[nJ][3] ; //lSepMot
										.And. aTmpSepFp[nL][4] == aTmpCli[nJ][4] ; //lSepOrd
										.And. aTmpSepFp[nL][5] == aTmpCli[nJ][5] ; //lRestGrp
										.And. aTmpSepFp[nL][6] == aTmpCli[nJ][6]   //lRestPrd

										lAchou := .T.
										AAdd(aTmpSepFp[nL][1],aTmpCli[nJ][1][nK])
										Exit
									Endif
								Next nM

								If lAchou
									Exit
								Endif
							Next nL

							If !lAchou
								AAdd(aTmpSepFp,{{aTmpCli[nJ][1][nK]},aTmpCli[nJ][2],aTmpCli[nJ][3],aTmpCli[nJ][4],aTmpCli[nJ][5],aTmpCli[nJ][6]})
							Endif
						Else
							AAdd(aTmpSepFp,{{aTmpCli[nJ][1][nK]},aTmpCli[nJ][2],aTmpCli[nJ][3],aTmpCli[nJ][4],aTmpCli[nJ][5],aTmpCli[nJ][6]})
						Endif
					Next nK
				Else
					AAdd(aTmpSepFp,{aTmpCli[nJ][1],aTmpCli[nJ][2],aTmpCli[nJ][3],aTmpCli[nJ][4],aTmpCli[nJ][5],aTmpCli[nJ][6]})
				Endif
			Next nJ

			//Verifica se há separação por motivo de saque
			For nJ := 1 To Len(aTmpSepFp)

				If aTmpSepFp[nJ][3] //.And. !IfVaziaS(aTmpSepFp[nJ][1]) //Separa motivo de saque e possui informação de saque

					For nK := 1 To Len(aTmpSepFp[nJ][1])

						If Len(aTmpSepMt) > 0

							lAchou :=  .F.

							For nL := 1 To Len(aTmpSepMt)

								For nM := 1 To Len(aTmpSepMt[nL][1])

									If aTmpSepMt[nL][1][nM][nPosMotiv] == aTmpSepFp[nJ][1][nK][nPosMotiv] ;
													.And. !Empty(aTmpSepMt[nL][1][nM][nPosMotiv]) ;
													.And. !Empty(aTmpSepFp[nJ][1][nK][nPosMotiv]) ;
												.And. aTmpSepMt[nL][2] == aTmpSepFp[nJ][2] ; //lSepFpg
												.And. aTmpSepMt[nL][3] == aTmpSepFp[nJ][3] ; //lSepMot
												.And. aTmpSepMt[nL][4] == aTmpSepFp[nJ][4] ; //lSepOrd
												.And. aTmpSepMt[nL][5] == aTmpSepFp[nJ][5] ; //lRestGrp
												.And. aTmpSepMt[nL][6] == aTmpSepFp[nJ][6]   //lRestPrd

										lAchou := .T.
										AAdd(aTmpSepMt[nL][1],aTmpSepFp[nJ][1][nK])
										Exit
									Endif
								Next nM

								If lAchou
									Exit
								Endif
							Next nL

							If !lAchou

								AAdd(aTmpSepMt,{{aTmpSepFp[nJ][1][nK]},aTmpSepFp[nJ][2],aTmpSepFp[nJ][3],aTmpSepFp[nJ][4],aTmpSepFp[nJ][5],aTmpSepFp[nJ][6]})
							Endif
						Else
							AAdd(aTmpSepMt,{{aTmpSepFp[nJ][1][nK]},aTmpSepFp[nJ][2],aTmpSepFp[nJ][3],aTmpSepFp[nJ][4],aTmpSepFp[nJ][5],aTmpSepFp[nJ][6]})
						Endif
					Next nK
				Else
					AAdd(aTmpSepMt,{aTmpSepFp[nJ][1],aTmpSepFp[nJ][2],aTmpSepFp[nJ][3],aTmpSepFp[nJ][4],aTmpSepFp[nJ][5],aTmpSepFp[nJ][6]})
				Endif
			Next nJ

			//Verifica se há separação por ordem de serviço
			For nJ := 1 To Len(aTmpSepMt)

				If aTmpSepMt[nJ][4] //.And. !IfVaziaO(aTmpSepMt[nJ][1]) //Separa ordem de serviço e possui ordem de serviço

					For nK := 1 To Len(aTmpSepMt[nJ][1])

						If Len(aTmpSepOs) > 0

							lAchou :=  .F.

							For nL := 1 To Len(aTmpSepOs)

								For nM := 1 To Len(aTmpSepOs[nL][1])

									If aTmpSepOs[nL][1][nM][nPosProdOs] == aTmpSepMt[nJ][1][nK][nPosProdOs]  ;
											.And. AllTrim(aTmpSepMt[nJ][1][nK][nPosPrefixo]) <> "VPO" ;
											.And. !Empty(aTmpSepOs[nL][1][nM][nPosProdOs]) ;
											.And. !Empty(aTmpSepMt[nJ][1][nK][nPosProdOs]) ;
										.And. aTmpSepOs[nL][2] == aTmpSepMt[nJ][2] ; //lSepFpg
										.And. aTmpSepOs[nL][3] == aTmpSepMt[nJ][3] ; //lSepMot
										.And. aTmpSepOs[nL][4] == aTmpSepMt[nJ][4] ; //lSepOrd
										.And. aTmpSepOs[nL][5] == aTmpSepMt[nJ][5] ; //lRestGrp
										.And. aTmpSepOs[nL][6] == aTmpSepMt[nJ][6]   //lRestPrd

										lAchou := .T.
										AAdd(aTmpSepOs[nL][1],aTmpSepMt[nJ][1][nK])
										Exit
									Endif
								Next nM

								If lAchou
									Exit
								Endif
							Next nL

							If !lAchou

								AAdd(aTmpSepOs,{{aTmpSepMt[nJ][1][nK]},aTmpSepMt[nJ][2],aTmpSepMt[nJ][3],aTmpSepMt[nJ][4],aTmpSepMt[nJ][5],aTmpSepMt[nJ][6]})
							Endif
						Else
							AAdd(aTmpSepOs,{{aTmpSepMt[nJ][1][nK]},aTmpSepMt[nJ][2],aTmpSepMt[nJ][3],aTmpSepMt[nJ][4],aTmpSepMt[nJ][5],aTmpSepMt[nJ][6]})
						Endif
					Next nK
				Else
					AAdd(aTmpSepOs,{aTmpSepMt[nJ][1],aTmpSepMt[nJ][2],aTmpSepMt[nJ][3],aTmpSepMt[nJ][4],aTmpSepMt[nJ][5],aTmpSepMt[nJ][6]})
				Endif
			Next nJ

			//Verifica se há restrição por Grupo de Produto
			For nJ := 1 To Len(aTmpSepOs)

				If aTmpSepOs[nJ][5] //.And. !RetRpVls(aTmpSepOs[nJ][1]) //Há restrição por Grupo de Produto e não se trata de um agrupamento de requisições ou vale

					For nK := 1 To Len(aTmpSepOs[nJ][1])

						If Len(aTmpGrp) > 0

							cGrpOri := ""

							//Grupo título de origem
							SD2->(DbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
							SD2->(DbGoTop())

							//D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
							If SD2->(DbSeek(aTmpSepOs[nJ][1][nK][nPosFilial]+aTmpSepOs[nJ][1][nK][nPosNumero]+aTmpSepOs[nJ][1][nK][nPosPrefixo]+aTmpSepOs[nJ][1][nK][nPosCliente]+aTmpSepOs[nJ][1][nK][nPosLoja])) //Exclusivo

								SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD
								SB1->(DbGoTop())

								If SB1->(DbSeek(xFilial("SB1")+SD2->D2_COD)) //Compartilhado

									cGrpOri := SB1->B1_GRUPO
								Endif
							Endif

							For nL := 1 To Len(aTmpGrp)

								For nM := 1 To Len(aTmpGrp[nL][1])

									lAchou :=  .F.
									cGrpDes := ""

									//Grupo título de destino
									SD2->(DbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
									SD2->(DbGoTop())

									//D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
									If SD2->(DbSeek(aTmpGrp[nL][1][nM][nPosFilial]+aTmpGrp[nL][1][nM][nPosNumero]+aTmpGrp[nL][1][nM][nPosPrefixo]+aTmpGrp[nL][1][nM][nPosCliente]+aTmpGrp[nL][1][nM][nPosLoja])) //Exclusivo

										SB1->(DbSetOrder(1)) //B1_FILIAL+B1_COD
										SB1->(DbGoTop())

										If SB1->(DbSeek(xFilial("SB1")+SD2->D2_COD)) //Compartilhado

											cGrpDest := SB1->B1_GRUPO
										Endif
									Endif

									If cGrpOri == cGrpDest ;
											.And. aTmpGrp[nL][2] == aTmpSepOs[nJ][2] ; //lSepFpg
										.And. aTmpGrp[nL][3] == aTmpSepOs[nJ][3] ; //lSepMot
										.And. aTmpGrp[nL][4] == aTmpSepOs[nJ][4] ; //lSepOrd
										.And. aTmpGrp[nL][5] == aTmpSepOs[nJ][5] ; //lRestGrp
										.And. aTmpGrp[nL][6] == aTmpSepOs[nJ][6]   //lRestPrd

										lAchou := .T.
										AAdd(aTmpGrp[nL][1],aTmpSepOs[nJ][1][nK])
										Exit
									Endif
								Next nM

								If lAchou
									Exit
								Endif
							Next nL

							If !lAchou
								AAdd(aTmpGrp,{{aTmpSepOs[nJ][1][nK]},aTmpSepOs[nJ][2],aTmpSepOs[nJ][3],aTmpSepOs[nJ][4],aTmpSepOs[nJ][5],aTmpSepOs[nJ][6]})
							Endif
						Else
							AAdd(aTmpGrp,{{aTmpSepOs[nJ][1][nK]},aTmpSepOs[nJ][2],aTmpSepOs[nJ][3],aTmpSepOs[nJ][4],aTmpSepOs[nJ][5],aTmpSepOs[nJ][6]})
						Endif
					Next nK
				Else
					AAdd(aTmpGrp,{aTmpSepOs[nJ][1],aTmpSepOs[nJ][2],aTmpSepOs[nJ][3],aTmpSepOs[nJ][4],aTmpSepOs[nJ][5],aTmpSepOs[nJ][6]})
				Endif
			Next nJ

			//Verifica se há restrição por Produto
			For nJ := 1 To Len(aTmpGrp)

				If aTmpGrp[nJ][6] //.And. !RetRpVls(aTmpGrp[nJ][1]) //Há restrição por Produto e não se trata de um agrupamento de requisições ou vale

					For nK := 1 To Len(aTmpGrp[nJ][1])

						If Len(aTmpProd) > 0

							cProdOri := ""

							//Produto título de origem
							SD2->(DbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
							SD2->(DbGoTop())

							If SD2->(DbSeek(aTmpGrp[nJ][1][nK][nPosFilial]+aTmpGrp[nJ][1][nK][nPosNumero]+aTmpGrp[nJ][1][nK][nPosPrefixo]+aTmpGrp[nJ][1][nK][nPosCliente]+aTmpGrp[nJ][1][nK][nPosLoja])) //Exclusivo
								cProdOri := SD2->D2_COD
							Endif

							For nL := 1 To Len(aTmpProd)

								For nM := 1 To Len(aTmpProd[nL][1])

									lAchou :=  .F.
									cProdDes := ""

									//Produto título de destino
									SD2->(DbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
									SD2->(DbGoTop())

									If SD2->(DbSeek(aTmpProd[nL][1][nM][nPosFilial]+aTmpProd[nL][1][nM][nPosNumero]+aTmpProd[nL][1][nM][nPosPrefixo]+aTmpProd[nL][1][nM][nPosCliente]+aTmpProd[nL][1][nM][nPosLoja])) //Exclusivo
										cProdDest := SD2->D2_COD
									Endif

									If cProdOri == cProdDest ;
											.And. aTmpProd[nL][2] == aTmpGrp[nJ][2] ; //lSepFpg
										.And. aTmpProd[nL][3] == aTmpGrp[nJ][3] ; //lSepMot
										.And. aTmpProd[nL][4] == aTmpGrp[nJ][4] ; //lSepOrd
										.And. aTmpProd[nL][5] == aTmpGrp[nJ][5] ; //lRestGrp
										.And. aTmpProd[nL][6] == aTmpGrp[nJ][6]   //lRestPrd

										lAchou := .T.
										AAdd(aTmpProd[nL][1],aTmpGrp[nJ][1][nK])
										Exit
									Endif
								Next nM

								If lAchou
									Exit
								Endif
							Next nL

							If !lAchou
								AAdd(aTmpProd,{{aTmpGrp[nJ][1][nK]},aTmpGrp[nJ][2],aTmpGrp[nJ][3],aTmpGrp[nJ][4],aTmpGrp[nJ][5],aTmpGrp[nJ][6]})
							Endif
						Else
							AAdd(aTmpProd,{{aTmpGrp[nJ][1][nK]},aTmpGrp[nJ][2],aTmpGrp[nJ][3],aTmpGrp[nJ][4],aTmpGrp[nJ][5],aTmpGrp[nJ][6]})
						Endif
					Next nK
				Else
					AAdd(aTmpProd,{aTmpGrp[nJ][1],aTmpGrp[nJ][2],aTmpGrp[nJ][3],aTmpGrp[nJ][4],aTmpGrp[nJ][5],aTmpGrp[nJ][6]})
				Endif
			Next nJ

			//Faturamento
			For nX := 1 To Len(aTmpProd)
				ExecOper(aTmpProd[nX][1],aCliente[nI][1],aCliente[nI][2])
			Next nX
		Next nI
	Endif

	If Select("QRYFAT") > 0
		QRYFAT->(DbCloseArea())
	Endif

Return

/***********************************************/
Static Function ExecOper(_aTit,_cCliente,_cLoja)
/***********************************************/

	Local aAuxFat 	:= {}
	Local aBoleto	:= {}
	Local aImp		:= {}
	Local _cImp		:= ""
	//Local aFormas	:= {}
	Local lImprime	:= .F.
	Local nContAux	:= 0
	Local cEmails	:= ""
	Local lEnvArqs	:= SuperGetMv("MV_XENVARQ",.F.,.T.)
	Local cImpPad	:= AllTrim(SuperGetMv("MV_XIMPPAD",.F.,"Doro"))
	Local nNroTen	:= SuperGetMv("MV_XNROTEN",.F.,3)
	Local nX
	Local cBlFuncBol
	Local cBlFuncFat
	Private lPDFFat		:= SuperGetMv("MV_XPDFFAT",.F.,.T.) //define se gera automatico o PDF da fatura no servidor, durante o processamento da fatura

	Private lFluxoFAT	:= .T. //Variavel para indicar que está no fluxo de faturamento (usada no boleto Decio)

	U_TRETE30B()

//Fatura
	Conout(">> EXECUTANDO FUNCAO FATURA - "+Time()+"")

	aAuxFat := U_TRETE016(_aTit,_cCliente,_cLoja,3)

	If Len(aAuxFat) > 0
		Conout("Fatura: " + aAuxFat[1][1])
	Endif

	Conout(">> FIM FUNCAO FATURA - "+Time()+"")

	If Len(aAuxFat) > 0

		DbSelectArea("U88")
		U88->(DbSetOrder(1)) //U88_FILIAL+U88_FORMAP+U88_CLIENT+U88_LOJA

		DbSelectArea("SE1")
		SE1->(DbSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

		If U88->(DbSeek(xFilial("U88")+"FT"+Space(4)+_cCliente+_cLoja)) //Compartilhado
		//	If U88->U88_FATCOR == "S" //Envia fatura //TODO: Marajo solicitou para não verificar tal informação.
		//		If !Empty(AllTrim(U88->U88_TPOCOR)) // Tipos que serão impressos na impressora.
		//			If SE1->(DbSeek(xFilial("SE1")+aAuxFat[1][2]+aAuxFat[1][3]+"FAT"+aAuxFat[1][1]))
		//				aFormas := OrigFatur(SE1->E1_FILIAL,SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA)
		//				For nX:=1 To Len(aFormas)
		//					If aFormas[nX] $ U88->U88_TPOCOR
		//						lImprime := .T.
		//						Exit
		//					EndIf
		//				Next nX
		//			EndIf
		//		Else
		//			lImprime := .T.
		//		EndIf

		//		If lImprime
					//Imprime Fatura
					if lPDFFat
						Conout(">> EXECUTANDO FUNCAO IMPRESSAO DE FATURA - "+Time()+"")
						cBlFuncFat := "U_"+cFImpFat+"(,cFilAnt,{{aAuxFat[1][1],aAuxFat[1][2],aAuxFat[1][3],aAuxFat[1][4],aAuxFat[1][5],aAuxFat[1][6]}},.T.,.T.,.T.,/*@aArqPDF*/)"
						&cBlFuncFat
						Conout(">> FIM FUNCAO IMPRESSAO DE FATURA - "+Time()+"")
					endif
		//		EndIf
		//	Endif

			If U88->U88_TPCOBR == "B" //Tipo de cobrança igual a Boleto bancário

				//Imprime Boleto
				Conout(">> EXECUTANDO FUNCAO IMPRESSAO DE BOLETO - "+Time()+"")
				
				DbSelectArea("SE1")
				SE1->(DbSetOrder(2)) //E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

				If SE1->(DbSeek(xFilial("SE1")+aAuxFat[1][2]+aAuxFat[1][3]+"FAT"+aAuxFat[1][1]))

					AAdd(aBoleto,SE1->E1_PREFIXO) 						//Prefixo - De
					AAdd(aBoleto,SE1->E1_PREFIXO) 						//Prefixo - Ate
					AAdd(aBoleto,SE1->E1_NUM) 							//Numero - De
					AAdd(aBoleto,SE1->E1_NUM) 							//Numero - Ate
					AAdd(aBoleto,SE1->E1_PARCELA) 						//Parcela - De
					AAdd(aBoleto,SE1->E1_PARCELA) 						//Parcela - Ate
					AAdd(aBoleto,SE1->E1_PORTADO) 						//Portador - De
					AAdd(aBoleto,SE1->E1_PORTADO) 						//Portador - Ate
					AAdd(aBoleto,SE1->E1_CLIENTE) 						//Cliente - De
					AAdd(aBoleto,SE1->E1_CLIENTE) 						//Cliente - Ate
					AAdd(aBoleto,SE1->E1_LOJA) 							//Loja - De
					AAdd(aBoleto,SE1->E1_LOJA) 							//Loja - Ate
					AAdd(aBoleto,SE1->E1_EMISSAO) 						//Emissão - De
					AAdd(aBoleto,SE1->E1_EMISSAO) 						//Eemissão- Ate
					AAdd(aBoleto,DataValida(SE1->E1_VENCTO)) 			//Vencimento - De
					AAdd(aBoleto,DataValida(SE1->E1_VENCTO)) 			//Vencimento - Ate
					AAdd(aBoleto,Space(TamSX3("E1_NUMBOR")[1])) 		//Nr. Bordero - De
					AAdd(aBoleto,Replicate("Z",TamSX3("E1_NUMBOR")[1])) //Nr. Bordero - Ate
					AAdd(aBoleto,Space(TamSX3("F2_CARGA")[1])) 			//Carga - De
					AAdd(aBoleto,Replicate("Z",TamSX3("F2_CARGA")[1])) 	//Carga - Ate
					AAdd(aBoleto,"") 									//Mensagem 1
					AAdd(aBoleto,"") 									//Mensagem 2

					If !IsBlind()
						aImp := GetImpWindows(.F.) //Busca a relacao de impressoras da estacao, onde a primeira da lista e a padrao
					Else
						aImp := GetImpWindows(.T.) //Busca a relacao de impressoras do server, onde a primeira da lista e a padrao

						For nX := 1 To Len(aImp)
							If cImpPad $ aImp[nX] //Força a impressora Rascunhho devido a alteração automática de impressora padrão no servidor
								_cImp := aImp[nX]
							Endif
						Next nX
					Endif

					If U88->U88_BOLCOR == "S" //Imprime Boleto
						lImprime := .T.
					Else
						lImprime := .F.
					Endif

					//U_TRETR009(aBoleto,IIF(!Empty(_cImp),_cImp,aImp[1]),,,lImprime)
					cBlFuncBol := "U_"+cFImpBol+"(aBoleto,IIF(!Empty(_cImp),_cImp,aImp[1]),,,lImprime)"
					&cBlFuncBol
				Endif

				Conout(">> FIM FUNCAO IMPRESSAO DE BOLETO - "+Time()+"")
			Endif

		Endif

		//Envio de e-mail com anexos do faturamento
		If lEnvArqs
			U_TRETE044(cFilAnt, {{aAuxFat[1][1],aAuxFat[1][2],aAuxFat[1][3],aAuxFat[1][4],aAuxFat[1][5],aAuxFat[1][6]}})
		Endif
	Endif

Return

/*********************************/
Static Function EnvMail(_aEnvMail)
/*********************************/

	Local oMail

	Local aDest		:= StrTokArr(GetMv("MV_XMAILFP"),";")
	Local cAssunto	:= "Cadastro Configurar Faturamento ausente - Protheus"
	Local cHtml		:= ""

	Local cFontHtml := "'Lucida Sans', Verdana, sans-serif"

	Local nI

	Local nTot		:= 0

	If Len(aDest) > 0

		Conout("########################################################################")
		Conout("Envio de e-mail, referente a ausencia do cadastro Configurar Faturamento")
		Conout("########################################################################")

		cHtml += '<html><body>'

		cHtml += '<table width="100%" border="0" cellspacing="1" cellpadding="3" style="font-family:'+cFontHtml+'; font-size:10px;">'
		cHtml += '  <tr>'
		cHtml += '    <td>Segue relação de título(s) não faturado(s):</td>'
		cHtml += '  </tr>'
		cHtml += '</table>'

		cHtml += '<br />'

		cHtml += '<table width="100%" border="1" cellspacing="0" cellpadding="3" style="font-family:'+cFontHtml+'; font-size:10px;">'
		cHtml += '  <tr>'
		cHtml += '      <td>'
		cHtml += '			<b>Filial</b>'
		cHtml += '	    </td>'
		cHtml += '      <td>'
		cHtml += '			<b>Cliente</b>'
		cHtml += '	    </td>'
		cHtml += '      <td>'
		cHtml += '			<b>Loja</b>'
		cHtml += '	    </td>'
		cHtml += '      <td>'
		cHtml += '			<b>Nome</b>'
		cHtml += '	    </td>'
		cHtml += '      <td>'
		cHtml += '			<b>Prefixo</b>'
		cHtml += '	    </td>'
		cHtml += '      <td>'
		cHtml += '			<b>Título</b>'
		cHtml += '	    </td>'
		cHtml += '      <td>'
		cHtml += '			<b>Parcela</b>'
		cHtml += '	    </td>'
		cHtml += '      <td>'
		cHtml += '			<b>Forma de pagto.</b>'
		cHtml += '	    </td>'
		cHtml += '      <td>'
		cHtml += '			<b>Descrição</b>'
		cHtml += '	    </td>'
		cHtml += '      <td>'
		cHtml += '			<b>Valor</b>'
		cHtml += '	    </td>'
		cHtml += '      <td>'
		cHtml += '			<b>Cond. pagto.</b>'
		cHtml += '	    </td>'
		cHtml += '      <td>'
		cHtml += '			<b>Classe</b>'
		cHtml += '	    </td>'
		cHtml += '  </tr>'

		For nI := 1 To Len(_aEnvMail)
			cHtml += '  <tr>'
			cHtml += '      <td>'
			cHtml += '			'+AllTrim(_aEnvMail[nI][1])+''
			cHtml += '	    </td>'
			cHtml += '      <td>'
			cHtml += '			'+AllTrim(_aEnvMail[nI][2])+''
			cHtml += '	    </td>'
			cHtml += '      <td>'
			cHtml += '			'+AllTrim(_aEnvMail[nI][3])+''
			cHtml += '	    </td>'
			cHtml += '      <td>'
			cHtml += '			'+AllTrim(Posicione("SA1",1,xFilial("SA1")+_aEnvMail[nI][2]+_aEnvMail[nI][3],"A1_NOME"))+''
			cHtml += '	    </td>'
			cHtml += '      <td>'
			cHtml += '			'+AllTrim(_aEnvMail[nI][4])+''
			cHtml += '	    </td>'
			cHtml += '      <td>'
			cHtml += '			'+AllTrim(_aEnvMail[nI][5])+''
			cHtml += '	    </td>'
			cHtml += '      <td>'
			cHtml += '			'+AllTrim(_aEnvMail[nI][6])+''
			cHtml += '	    </td>'
			cHtml += '      <td>'
			cHtml += '			'+AllTrim(_aEnvMail[nI][7])+''
			cHtml += '	    </td>'
			cHtml += '      <td>'
			cHtml += '			'+AllTrim(Posicione("SX5",1,xFilial("SX5")+"05"+_aEnvMail[nI][7],"X5_DESCRI"))+''
			cHtml += '	    </td>'
			cHtml += '      <td>'
			cHtml += '			'+Transform(_aEnvMail[nI][8],"@E 9,999,999,999,999.99")+''
			cHtml += '	    </td>'
			cHtml += '      <td>'
			cHtml += '			'+AllTrim(_aEnvMail[nI][9])+''
			cHtml += '	    </td>'
			cHtml += '      <td>'
			If "'OK'" $ AllTrim(_aEnvMail[nI][10])
				cHtml += '      <font color="#FF0000">'
				cHtml += '			'+AllTrim(_aEnvMail[nI][10])+''
				cHtml += '      </font>'
			Else
				cHtml += '			'+AllTrim(_aEnvMail[nI][10])+''
			Endif
			cHtml += '	    </td>'
			cHtml += '  </tr>'

			nTot += _aEnvMail[nI][8]
		Next

		cHtml += '</table>'

		cHtml += '<br />'

		cHtml += '<table width="100%" border="0" cellspacing="1" cellpadding="3" style="font-family:'+cFontHtml+'; font-size:10px;">'
		cHtml += '  <tr>'
		cHtml += '    <td>Quantidade de título(s): '+cValToChar(Len(_aEnvMail))+'</td>'
		cHtml += '  </tr>'
		cHtml += '  <tr>'
		cHtml += '    <td>Total do(s) título(s): '+Transform(nTot,"@E 9,999,999,999,999.99")+'</td>'
		cHtml += '  </tr>'
		cHtml += '</table>'

		//Parâmetros necessários á rotina
		// MV_RELACNT - Conta a ser utilizada no envio de E-Mail
		// MV_RELFROM - E-mail utilizado no campo FROM no envio
		// MV_RELSERV - Nome do Servidor de Envio de E-mail utilizado no envio
		// MV_RELAUTH - Determina se o Servidor de Email necessita de Autenticação
		// MV_RELAUSR - Usuário para Autenticação no Servidor de Email
		// MV_RELAPSW - Senha para Autenticação no Servidor de Email
		// MV_XMAILEX - Email destinatário

		For nI := 1 To Len(aDest)

			oMail := LTpSendMail():New(AllTrim(aDest[nI]),cAssunto,cHtml)
			oMail:SetShedule(.T.)
			oMail:Send()
		Next

		Conout("###############################################################################")
		Conout("Fim do envio de e-mail, referente a ausencia do cadastro Configurar Faturamento")
		Conout("###############################################################################")
	Endif

Return

/******************************/
Static Function RetRpVls(_aAux)
/******************************/

	Local lRet := .F.
	Local nI

	For nI := 1 To Len(_aAux)

		If AllTrim(_aAux[nI][nPosTipo]) == "RP" .Or. AllTrim(_aAux[nI][nPosTipo]) == "VLS"
			lRet := .T.
			Exit
		Endif
	Next

Return lRet

/******************************/
Static Function IfVaziaS(_aAux)
/******************************/

	Local lRet := .F.
	Local nI

	For nI := 1 To Len(_aAux)

		If Empty(_aAux[nI][nPosMotiv])
			lRet := .T.
			Exit
		Endif
	Next

Return lRet

/******************************/
Static Function IfVaziaO(_aAux)
/******************************/

	Local lRet := .F.
	Local nI

	For nI := 1 To Len(_aAux)

		If Empty(_aAux[nI][nPosProdOs])
			lRet := .T.
			Exit
		Endif
	Next

Return lRet

/*****************************************************************/
Static Function OrigFatur(cFil,cPref,cTit,cParc,cTp,cCli,cLojaCli)
/*****************************************************************/

	Local aRet 	:= ""
	Local cQry	:= ""

	cQry := " SELECT SE1.E1_TIPO
	cQry += CRLF + " FROM " + RetSqlName("SE1") + " SE1 INNER JOIN "+RetSqlName("FI7")+" FI7 ON SE1.E1_PREFIXO 	= FI7.FI7_PRFORI"
	cQry += CRLF + " 																			AND SE1.E1_NUM 		= FI7.FI7_NUMORI"
	cQry += CRLF + " 																			AND SE1.E1_PARCELA 	= FI7.FI7_PARORI"
	cQry += CRLF + " 																			AND SE1.E1_TIPO 	= FI7.FI7_TIPORI"
	cQry += CRLF + " 																			AND SE1.E1_CLIENTE 	= FI7.FI7_CLIORI"
	cQry += CRLF + " 																			AND SE1.E1_LOJA 	= FI7.FI7_LOJORI"
	cQry += CRLF + " 																			AND FI7.FI7_PRFDES	= '"+cPref+"'"
	cQry += CRLF + " 																			AND FI7.FI7_NUMDES	= '"+cTit+"'"
	cQry += CRLF + " 																			AND FI7.FI7_PARDES	= '"+cParc+"'"
	cQry += CRLF + " 																			AND FI7.FI7_TIPDES	= '"+cTp+"'"
	cQry += CRLF + " 																			AND FI7.FI7_CLIDES	= '"+cCli+"'"
	cQry += CRLF + " 																			AND FI7.FI7_LOJDES	= '"+cLojaCli+"'"
	cQry += CRLF + " 																			AND FI7.D_E_L_E_T_ = ' '"
	cQry += CRLF + " 																			AND FI7.FI7_FILIAL	= '"+xFilial("FI7")+"'"

	If Select("ORI") > 0
		ORI->( DbCloseArea() )
	EndIf

	cQry := ChangeQuery(cQry)

	TcQuery cQry New Alias "ORI"

	If Contar("ORI", "!EOF()") > 0

		ORI->(DbGoTop())

		While ORI->(!EOF())
			Aadd(aRet,{ORI->E1_TIPO})
			ORI->(DbSkip())
		EndDo
	EndIf

	ORI->(DbCloseArea())

Return aRet

/***********************/
User Function TRETE30B()
/***********************/

//Local aDirUser		:= Directory(GetTempPath() + "SC??????")
	Local aDirSystem	:= Directory("\system\SC??????")
//Local aDirTemp		:= Directory("\temp\SC??????")
	Local nX

Conout(IIF(IsBlind(),"IsBlind igual a True","IsBlind igual a False"))

/*If Len(aDirUser) > 0

	//Limpeza dos arquivos do tipo SC*.LOG da system, em função do erro na geração do PDF da Fatura e Boleto Bancário 
	Conout(">> INICIO LIMPEZA DOS ARQUIVOS DO TIPO SC*.LOG DO USER TEMP - "+Time()+"")   
	For nX := 1 To Len(aDirUser)
	
		//Realiza backup do arquivo
		If __CopyFile(GetTempPath() + aDirUser[nX][1],"\system\bkp_arquivos_log\" + aDirUser[nX][1])
			Conout("Arquivo " + aDirUser[nX][1] + " copiado.")   
		Endif
	
		//Exclui o arquivo
		If FErase(GetTempPath() + aDirUser[nX][1]) == 0
			Conout("Arquivo " + aDirUser[nX][1] + " apagado.")
		Endif
	Next
	Conout(">> FIM DA LIMPEZA DOS ARQUIVOS DO TIPO SC*.LOG DO USER TEMP - "+Time()+"")  
Endif
*/

If Len(aDirSystem) > 0

	//Limpeza dos arquivos do tipo SC*.LOG da system, em função do erro na geração do PDF da Fatura e Boleto Bancário
	Conout(">> INICIO LIMPEZA DOS ARQUIVOS DO TIPO SC* DA SYSTEM - "+Time()+"")
	For nX := 1 To Len(aDirSystem)

		//Realiza backup do arquivo
		If __CopyFile("\system\" + aDirSystem[nX][1],"\system\bkp_arquivos_log\" + aDirSystem[nX][1])
			Conout("Arquivo " + aDirSystem[nX][1] + " copiado.")
		Endif

		//Exclui o arquivo
		If FErase("system\" + aDirSystem[nX][1]) == 0
			Conout("Arquivo " + aDirSystem[nX][1] + " apagado.")
		Endif
	Next
	Conout(">> FIM DA LIMPEZA DOS ARQUIVOS DO TIPO SC* DA SYSTEM - "+Time()+"")
Endif

/*
If Len(aDirTemp) > 0

	//Limpeza dos arquivos do tipo SC*.LOG da system, em função do erro na geração do PDF da Fatura e Boleto Bancário 
	Conout(">> INICIO LIMPEZA DOS ARQUIVOS DO TIPO SC*.LOG DA TEMP - "+Time()+"")   
	For nX := 1 To Len(aDirTemp)
	
		//Realiza backup do arquivo
		If __CopyFile("\temp\" + aDirTemp[nX][1],"\system\bkp_arquivos_log\" + aDirTemp[nX][1])
			Conout("Arquivo " + aDirTemp[nX][1] + " copiado.")   
		Endif
	
		//Exclui o arquivo
		If FErase("temp\" + aDirTemp[nX][1]) == 0
			Conout("Arquivo " + aDirTemp[nX][1] + " apagado.")
		Endif
	Next
	Conout(">> FIM DA LIMPEZA DOS ARQUIVOS DO TIPO SC*.LOG DA TEMP - "+Time()+"")  
Endif
*/

Return

/*************************************/
User Function TRETE30D(aArqPDF,cEmails)
/*************************************/

	Local oMail

	Local aDest		:= StrTokArr(cEmails,";")
	Local cNomEmp 	:= SuperGetMv("MV_XNOMEMP",.F.,"MV_XNOMEMP")
	Local cAssunto	:= "Envio automático de arquivos de faturamento - "+AllTrim(cNomEmp)+""
	Local cCc		:= SuperGetMv("MV_XMAILCC",.F.,"")
	Local cHtml		:= ""
	Local cFiles	:= ""

	Local lArqFat	:= .F.
	Local lArqBol	:= .F.
	Local lArqNf	:= .F.

	Local cFontHtml := "'Lucida Sans', Verdana, sans-serif"

	Local nI,nJ

	If Len(aDest) > 0

		Conout("########################################################")
		Conout("Envio de e-mail, referente a arquivos PDFs - Faturamento")
		Conout("########################################################")

		cHtml += '<html><body>'

		cHtml += '<table width="100%" border="0" cellspacing="1" cellpadding="3" style="font-family:'+cFontHtml+'; font-size:12px;">'
		cHtml += '  <tr>'
		cHtml += '    <td>Prezado Cliente,</td>'
		cHtml += '  </tr>'
		cHtml += '  <tr>'
		cHtml += '    <td></td>'
		cHtml += '  </tr>'
		cHtml += '  <tr>'
		cHtml += '    <td>Segue o faturamento '+AllTrim(SM0->M0_FILIAL)+' - '+AllTrim(SM0->M0_NOMECOM)+'.</td>'
		cHtml += '  </tr>'
		cHtml += '  <tr>'
		cHtml += '    <td></td>'
		cHtml += '  </tr>'

		For nI := 1 To Len(aArqPDF)
			If "FATURA" $ aArqPDF[nI]
				lArqFat := .T.
			ElseIf "BOLETO" $ aArqPDF[nI]
				lArqBol := .T.
			ElseIf "NF"  $ aArqPDF[nI]
				lArqNf := .T.
			Endif
		Next

		//Verifica se há Fatura dentre os arquivos a serem enviados
		If lArqFat
			cHtml += '  <tr>'
			cHtml += '    <td>* Fatura</td>'
			cHtml += '  </tr>'
		Endif

		//Verifica se há Boleto Bancário dentre os arquivos a serem enviados
		If lArqBol
			cHtml += '  <tr>'
			cHtml += '    <td>* Boleto</td>'
			cHtml += '  </tr>'
		Endif

		//Verifica se há Boleto Bancário dentre os arquivos a serem enviados
		If lArqNf
			cHtml += '  <tr>'
			cHtml += '    <td>* Nota Fiscal</td>'
			cHtml += '  </tr>'
		Endif

		cHtml += '</table>'

		//Parâmetros necessários á rotina
		// MV_RELACNT - Conta a ser utilizada no envio de E-Mail
		// MV_RELFROM - E-mail utilizado no campo FROM no envio
		// MV_RELSERV - Nome do Servidor de Envio de E-mail utilizado no envio
		// MV_RELAUTH - Determina se o Servidor de Email necessita de Autenticação
		// MV_RELAUSR - Usuário para Autenticação no Servidor de Email
		// MV_RELAPSW - Senha para Autenticação no Servidor de Email
		// MV_XMAILEX - Email destinatário

		For nI := 1 To Len(aDest)

			oMail := LTpSendMail():New(AllTrim(aDest[nI]),cAssunto,cHtml)
			oMail:SetShedule(.T.)

			For nJ := 1 To Len(aArqPDF)
				If nJ == 1
					cFiles += aArqPDF[nJ] + ".pdf"
				Else
					cFiles += "," + aArqPDF[nJ] + ".pdf"
				Endif
				Conout("Anexando arquivo: " + aArqPDF[nJ] + ".pdf")
			Next nJ

			If !Empty(cCc)
				oMail:SetCc(cCc)
			Endif
			oMail:SetAttachment(cFiles)
			oMail:Send()
		Next nI

		Conout("###############################################################")
		Conout("Fim do envio de e-mail, referente a arquivos PDFs - Faturamento")
		Conout("###############################################################")
	Endif

Return

/***********************************************************************/
User Function TRETE30C(cFil,cCli,cLojaCli,cPref,cTit,cParc,cTp,aArqPDF)
/***********************************************************************/

	Local cQry 		:= ""

	Local cNomDoc	:= ""
	Local cNomArq	:= ""

	Local cDirDanfe := Alltrim(SuperGetMV("MV_XDIRDAN",.T.,"arquivos_mo\danfes\"))
	Local cDirDes	:= ""
	Local nI
	Local lAchou	:= .F.
	Local lArqPdf1	:= Type("aArqPDF") <> "U"
	Local lArqPdf2	:= Type("__aArqPDF") <> "U"

	If Select("QRYDANFE") > 0
		QRYDANFE->(dbCloseArea())
	Endif

	cQry := "SELECT DISTINCT SF2.F2_FILIAL, SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_CLIENTE, SF2.F2_LOJA"
	cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1, "+RetSqlName("SF2")+" SF2"
	cQry += CRLF + " WHERE SE1.D_E_L_E_T_ = ' '"
	cQry += CRLF + " AND SF2.D_E_L_E_T_ = ' '"

	If cFil == Nil
		cQry += CRLF + " AND SE1.E1_FILIAL 	= '"+xFilial("SE1")+"'"
		cQry += CRLF + " AND SF2.F2_FILIAL 	= '"+xFilial("SF2")+"'"
	Else
		cQry += CRLF + " AND SE1.E1_FILIAL 	= '"+cFil+"'"
		cQry += CRLF + " AND SF2.F2_FILIAL 	= '"+cFil+"'"
	Endif

	cQry += CRLF + " AND SE1.E1_FILIAL		= SF2.F2_FILIAL"
	cQry += CRLF + " AND SE1.E1_NUM		= SF2.F2_DOC"
	cQry += CRLF + " AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
	cQry += CRLF + " AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
	cQry += CRLF + " AND SE1.E1_LOJA		= SF2.F2_LOJA"
	cQry += CRLF + " AND SE1.E1_CLIENTE	= '"+cCli+"'"
	cQry += CRLF + " AND SE1.E1_LOJA		= '"+cLojaCli+"'"
	cQry += CRLF + " AND SE1.E1_PREFIXO	= '"+cPref+"'"
	cQry += CRLF + " AND SE1.E1_NUM		= '"+cTit+"'"
	cQry += CRLF + " AND SE1.E1_PARCELA	= '"+cParc+"'"
	cQry += CRLF + " AND SE1.E1_TIPO		= '"+cTp+"'"
	cQry += CRLF + " AND SF2.F2_ESPECIE	= 'SPED '" //NF-e

	cQry += CRLF + " ORDER BY 1"

	cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\QRYDANFE.txt",cQry)
	TcQuery cQry NEW Alias "QRYDANFE"

	While QRYDANFE->(!EOF())

		cNomDoc	:= "DANFE_" + QRYDANFE->F2_FILIAL + "_" + AllTrim(QRYDANFE->F2_DOC) + AllTrim(QRYDANFE->F2_SERIE) + "_" + AllTrim(QRYDANFE->F2_CLIENTE) + AllTrim(QRYDANFE->F2_LOJA)

		cDirDes := "system\"+cDirDanfe
		aDirAux := Directory(cDirDes+'*.pdf')

		lAchou := .F.

		//Percorre os arquivos
		For nI := 1 To Len(aDirAux)

			//Pegando o nome do arquivo
			cNomArq := aDirAux[nI][1]

			//Verifica o registro contém PDF
			If cNomDoc $ cNomArq

				If lArqPdf1
					Conout("Anexo DANFE: " + "\system\" + cDirDanfe + cNomArq)
					AAdd(aArqPDF,"\system\" + cDirDanfe + cNomArq)
				Endif
				If lArqPdf2
					Conout("Anexo DANFE: " + "\system\" + cDirDanfe + cNomArq)
					AAdd(__aArqPDF,"\system\" + cDirDanfe + cNomArq)
				Endif

				lAchou := .T.
				Exit
			Endif
		Next

		If !lAchou
			Conout("Anexo DANFE: " + "\system\" + cDirDanfe + cNomDoc + "nao localizado!")
		Endif

		QRYDANFE->(DbSkip())
	EndDo

Return

/***********************/
Static Function RetFer()
/***********************/

	Local lRet 		:= .F.

	Local dDtAtuC	:= DToC(Date())
	Local dDtAtuA	:= SubStr(DToC(Date()),1,5)

	Local aContent := {} // Vetor com os dados do SX5com: [1] FILIAL [2] TABELA [3] CHAVE [4] DESCRICAO
	Local nX := 1

	aContent := FWGetSX5("63")

	For nX:=1 to Len(aContent)

		//Verifica o tipo de feriado
		If Empty(SubStr(aContent[nX][4],6,2)) //Feriado nacional
			If dDtAtuA $ AllTrim(aContent[nX][4])
				lRet := .T.
				Exit
			Endif
		Else //Feriado móvel
			If dDtAtuC $ AllTrim(aContent[nX][4])
				lRet := .T.
				Exit
			Endif
		Endif

	Next nX

Return lRet

/******************************************************************/
User Function TRETE30A(cPref,cNum,cParcela,cTipo,cCliente,cLojaCli)
/******************************************************************/

	Local lRet 	:= .F.
	Local cQry	:= ""
	Local aArea	:= GetArea()

	If Select("QRYLIQ") > 0
		QRYLIQ->(DbCloseArea())
	Endif

	cQry := "SELECT SE1.E1_NUM"
	cQry += CRLF + " FROM "+RetSqlName("SE1")+" SE1 INNER JOIN "+RetSqlName("FI7")+" FI7	ON SE1.E1_PREFIXO 		= FI7.FI7_PRFORI"
	cQry += CRLF + " 																			AND SE1.E1_NUM 		= FI7.FI7_NUMORI"
	cQry += CRLF + " 																			AND SE1.E1_PARCELA 	= FI7.FI7_PARORI"
	cQry += CRLF + " 																			AND SE1.E1_TIPO 	= FI7.FI7_TIPORI"
	cQry += CRLF + " 																			AND SE1.E1_CLIENTE 	= FI7.FI7_CLIORI"
	cQry += CRLF + " 																			AND SE1.E1_LOJA 	= FI7.FI7_LOJORI"
	cQry += CRLF + " 																			AND FI7.D_E_L_E_T_ = ' '"
	cQry += CRLF + " 																			AND FI7.FI7_FILIAL	= '"+xFilial("FI7")+"'"
	cQry += CRLF + " WHERE SE1.D_E_L_E_T_ <> '*'"
	cQry += CRLF + " AND SE1.E1_FILIAL		= '"+xFilial("SE1")+"'"
	cQry += CRLF + " AND SE1.E1_PREFIXO	= '"+cPref+"'"
	cQry += CRLF + " AND SE1.E1_NUM		= '"+cNum+"'"
	cQry += CRLF + " AND SE1.E1_PARCELA	= '"+cParcela+"'"
	cQry += CRLF + " AND SE1.E1_TIPO		= '"+cTipo+"'"
	cQry += CRLF + " AND SE1.E1_CLIENTE	= '"+cCliente+"'"
	cQry += CRLF + " AND SE1.E1_LOJA		= '"+cLojaCli+"'"

	cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\TRETE030.txt",cQry)
	TcQuery cQry NEW Alias "QRYLIQ"

	If QRYLIQ->(!EOF())
		lRet := .T.
	Endif

	If Select("QRYLIQ") > 0
		QRYLIQ->(DbCloseArea())
	Endif

	RestArea(aArea)

Return lRet

/******************************************************/
Static Function RetSerVd(cDoc,cSerie,cCliente,cLojaCli)
/******************************************************/

	Local cSerVd 	:= ""
	Local cQry		:= ""

	If Select("QRYVENDA") > 0
		QRYVENDA->(DbCloseArea())
	Endif

	cQry := "SELECT SF2.F2_SERIE"
	cQry += CRLF + " FROM "+RetSqlName("SF2")+" SF2"
	cQry += CRLF + " WHERE SF2.D_E_L_E_T_ = ' '"
	cQry += CRLF + " AND SF2.F2_FILIAL 	= '"+xFilial("SF2")+"'"
	cQry += CRLF + " AND SF2.F2_DOC		= '"+cDoc+"'"
	cQry += CRLF + " AND SF2.F2_SERIE		= '"+cSerie+"'"
	cQry += CRLF + " AND SF2.F2_CLIENTE	= '"+cCliente+"'"
	cQry += CRLF + " AND SF2.F2_LOJA		= '"+cLojaCli+"'"

	cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\QRYVENDA.txt",cQry)
	TcQuery cQry NEW Alias "QRYVENDA"

	If QRYVENDA->(!EOF())
		cSerVd := QRYVENDA->F2_SERIE
	EndIf

	If Select("QRYVENDA") > 0
		QRYVENDA->(DbCloseArea())
	Endif

Return cSerVd

/*****************************************************/
Static Function TemDev(cFil,cTit,cPref,cCli,cLojaCli)
/*****************************************************/

	Local lRet := .F.
	Local cQry := ""

	If Select("QRYDEV") > 0
		QRYDEV->(dbCloseArea())
	Endif

	cQry := "SELECT SD1.D1_DOC"
	cQry += CRLF + " FROM "+RetSqlName("SD1")+" SD1"
	cQry += CRLF + " WHERE SD1.D_E_L_E_T_ = ' '"

	If cFil == Nil
		cQry += CRLF + " AND SD1.D1_FILIAL 	= '"+xFilial("SD1")+"'"
	Else
		cQry += CRLF + " AND SD1.D1_FILIAL 	= '"+cFil+"'"
	Endif

	cQry += CRLF + " AND SD1.D1_TIPO		= 'D'" // Devolução
	cQry += CRLF + " AND SD1.D1_NFORI		= '"+cTit+"'"
	cQry += CRLF + " AND SD1.D1_SERIORI	= '"+cPref+"'"
	cQry += CRLF + " AND SD1.D1_FORNECE	= '"+cCli+"'"
	cQry += CRLF + " AND SD1.D1_LOJA		= '"+cLojaCli+"'"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETE017.txt",cQry)
	TcQuery cQry NEW Alias "QRYDEV"

	If QRYDEV->(!EOF())
		lRet := .T.
	Endif

	If Select("QRYDEV") > 0
		QRYDEV->(dbCloseArea())
	Endif

Return lRet

/*************************************************/
Static Function PesqCxAbe(_nRecNo)
/*************************************************/

	Local lRet := .F.
	Local cQry := ""

	If Select("QRYCX") > 0
		QRYCX->(dbCloseArea())
	Endif

	cQry := "SELECT 1 "
	cQry += CRLF + " FROM "+RetSqlName("SL1")+" SL1 "
	cQry += CRLF + " INNER JOIN "+RetSqlName("SE1")+" SE1 ON ( "
	cQry += CRLF + " 	SE1.D_E_L_E_T_ = SL1.D_E_L_E_T_ "
	cQry += CRLF + " 	AND E1_FILIAL = L1_FILIAL "
	cQry += CRLF + " 	AND E1_PREFIXO = L1_SERIE "
	cQry += CRLF + " 	AND E1_NUM = L1_DOC "
	//cQry += CRLF + " 	AND E1_CLIENTE = L1_CLIENTE "
	//cQry += CRLF + " 	AND E1_LOJA = L1_LOJA "
	cQry += CRLF + " 	AND E1_EMISSAO = L1_EMISNF "
	cQry += CRLF + " 	) "
	cQry += CRLF + " INNER JOIN "+RetSqlName("SLW")+" SLW ON ( "
	cQry += CRLF + " 	SLW.D_E_L_E_T_ = SL1.D_E_L_E_T_ "
	cQry += CRLF + " 	AND LW_FILIAL = L1_FILIAL "
	cQry += CRLF + " 	AND LW_OPERADO = L1_OPERADO "
	cQry += CRLF + " 	AND LW_NUMMOV = L1_NUMMOV "
	cQry += CRLF + " 	AND RTRIM(LW_PDV) = RTRIM(L1_PDV) "
	cQry += CRLF + " 	AND LW_ESTACAO  = L1_ESTACAO "
	cQry += CRLF + " 	AND ( (L1_EMISNF+SUBSTRING(L1_HORA,1,5) BETWEEN LW_DTABERT+LW_HRABERT AND LW_DTFECHA+LW_HRFECHA) "
	cQry += CRLF + "      OR (LW_DTFECHA = ' ' AND L1_EMISNF+SUBSTRING(L1_HORA,1,5) >= LW_DTABERT+LW_HRABERT) )" //caixas nao fechados
	cQry += CRLF + " ) "
	cQry += CRLF + " WHERE SL1.D_E_L_E_T_ = ' ' "
	cQry += CRLF + " AND LW_CONFERE <> '1' "//-- diferente de 'Caixa Conferido'
	cQry += CRLF + " AND SE1.R_E_C_N_O_ = '"+alltrim(str(_nRecNo))+"'"

	cQry := ChangeQuery(cQry)
	//MemoWrite("c:\temp\TRETE017.txt",cQry)
	TcQuery cQry NEW Alias "QRYCX"

	If QRYCX->(!EOF())
		lRet := .T. //titulo pertece a um caixa não conferido
	Endif

	If Select("QRYCX") > 0
		QRYCX->(dbCloseArea())
	Endif

Return lRet
