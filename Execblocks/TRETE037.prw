
#include "topconn.ch"
#include "RPTDEF.CH"
#include "Shell.ch"

/*/{Protheus.doc} TRETE037
Faturamento Manual - Imprime NFE
@author Maiki Perin
@since 21/07/2014
@version P11
@param Filial, Prefixo, Numero, Cliente e Loja
@return nulo
/*/
User Function TRETE037(cFil,cTipo,cNumero,cCliente,cLojaCli)

	Local lRet := .F.
	//Local cDirDanfe		:= ""
	Local oBjNfe
	Local oSetup
	Local _aEmpresas	:= {}
	Local _ixe			:= 1
	Local aImp 			:= GetImpWindows(.F.) //Busca a relacao de impressoras da estacao, onde a primeira da lista e a padrao
	Local cAliasSX1 := GetNextAlias() // apelido para o arquivo de trabalho
	Local lOpen   	:= .F. // valida se foi aberto a tabela
	Local cMV_CH := ""

	DbSelectArea("SF2")
	SF2->(DbSetOrder(1)) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO

	cQry := " SELECT ID_ENT, CNPJ "
	cQry += " FROM SPED001 SPD001 WHERE R_E_C_D_E_L_ = 0 "
	cQry := Changequery(cQry)

	TcQuery cQry NEW Alias "SPD001"

	SPD001->( DbGoTop() )
	if SPD001->( Eof() )
		// Não existe empresas configuradas
		SPD001->( DbCloseArea() )
		Return
	endif

	while !SPD001->( Eof() )

		aadd(_aEmpresas, {SPD001->ID_ENT, SPD001->CNPJ, "", "", "", ""})
		SPD001->( DbSkip() )

	enddo
	SPD001->( DbCloseArea() )

	if Len(_aEmpresas) == 0
		Return
	endif

	_nPosSM0 := SM0->( RecNo() )
	SM0->( DbGoTop() )
	while !SM0->( Eof() )

		_nPos := aScan(_aEmpresas, {|x| AllTrim( x[2] ) == AllTrim(SM0->M0_CGC)} )
		if _nPos > 0
			_aEmpresas[_nPos][03] := SM0->M0_CODIGO
			_aEmpresas[_nPos][04] := AllTrim(SM0->M0_CODFIL)
		endif

		SM0->( DbSkip() )

	enddo
	SM0->( DbGoTo(_nPosSM0) )

	_cQry := " SELECT  ID_ENT, PARAMETRO, CONTEUDO"
	_cQry += " FROM SPED000 SPD000 WHERE R_E_C_D_E_L_ = 0 "
	_cQry := Changequery(_cQry)

	TcQuery _cQry NEW Alias "SPD000"

	SPD000->( DbGoTop() )
	if SPD000->( Eof() )
		SPD000->( DbCloseArea() )
		Return
	endif

	while !SPD000->( Eof() )

		_nPos := aScan(_aEmpresas, {|x| AllTrim( x[1] ) == AllTrim(SPD000->ID_ENT)} )
		if _nPos > 0 .and. 'MV_AMBIENT' $ AllTrim(SPD000->PARAMETRO)
			_aEmpresas[_nPos][05] := AllTrim(SPD000->CONTEUDO)
		elseif _nPos > 0 .and. 'MV_MODALID' $ AllTrim(SPD000->PARAMETRO)
			_aEmpresas[_nPos][06] := AllTrim(SPD000->CONTEUDO)
		endif

		SPD000->( DbSkip() )

	enddo
	SPD000->( DbCloseArea() )

	_ixe := aScan( _aEmpresas, {|x| x[3] == cEmpAnt .and. x[4] == cFil } )

	If Select("QRYNF") > 0
		QRYNF->(DbCloseArea())
	Endif

	cQry := "SELECT DISTINCT SF2.F2_NFCUPOM"
	cQry += " FROM "+RetSqlName("SE1")+" SE1, "+RetSqlName("SF2")+" SF2"
	cQry += " WHERE SE1.D_E_L_E_T_	<> '*'"
	cQry += " AND SF2.D_E_L_E_T_	<> '*'"
	cQry += " AND SE1.E1_FILIAL		= '"+xFilial("SE1",cFil)+"'"
	cQry += " AND SF2.F2_FILIAL		= '"+xFilial("SF2",cFil)+"'"
	cQry += " AND SE1.E1_FILIAL		= SF2.F2_FILIAL"
	cQry += " AND SE1.E1_NUM		= SF2.F2_DOC"
	cQry += " AND SE1.E1_PREFIXO	= SF2.F2_SERIE"
	cQry += " AND SE1.E1_CLIENTE	= SF2.F2_CLIENTE"
	cQry += " AND SE1.E1_LOJA		= SF2.F2_LOJA"

	If AllTrim(cTipo) == "FT"
		cQry += " AND SE1.E1_FATURA		= '"+cNumero+"'"
	Else
		cQry += " AND SE1.E1_NUM		= '"+cNumero+"'"
		cQry += " AND SE1.E1_CLIENTE	= '"+cCliente+"'"
		cQry += " AND SE1.E1_LOJA		= '"+cLojaCli+"'"
	Endif

	cQry += " AND (SF2.F2_NFCUPOM	<> ' ' AND SF2.F2_NFCUPOM <> 'MDL-RECORDED')" //Haja NF s/ CF
	cQry += " ORDER BY 1"

	cQry := ChangeQuery(cQry)
//MemoWrite("c:\temp\QRYNF.txt",cQry)
	TcQuery cQry NEW Alias "QRYNF"

	If QRYNF->(!EOF())

		While QRYNF->(!EOF())

			If Select("QRYNFCF") > 0
				QRYNFCF->(DbCloseArea())
			Endif

			cQry2 := "SELECT SF2.F2_CHVNFE,"
			cQry2 += " SF2.F2_DOC,"
			cQry2 += " SF2.F2_SERIE,"
			cQry2 += " SF2.F2_EMISSAO,"
			cQry2 += " SF2.F2_CLIENTE,"
			cQry2 += " SF2.F2_LOJA"
			cQry2 += " FROM "+RetSqlName("SF2")+" SF2"
			cQry2 += " WHERE SF2.D_E_L_E_T_	<> '*'"
			cQry2 += " AND SF2.F2_FILIAL	= '"+xFilial("SF2",cFil)+"'"
			cQry2 += " AND SF2.F2_DOC		= '"+SubStr(QRYNF->F2_NFCUPOM,4,9)+"'"
			cQry2 += " AND SF2.F2_SERIE		= '"+SubStr(QRYNF->F2_NFCUPOM,1,3)+"'"
			cQry2 += " ORDER BY 1,2,3"

			cQry2 := ChangeQuery(cQry2)
			//MemoWrite("c:\temp\QRYNF.txt",cQry)
			TcQuery cQry2 NEW Alias "QRYNFCF"

			If QRYNFCF->(!EOF())

				_cQry := "SELECT NFE_ID"
				_cQry += " FROM SPED050 SPD050, " + RetSqlName("SF2") + " SF2"
				_cQry += " WHERE SPD050.D_E_L_E_T_	= ' '"
				_cQry += " AND SF2.D_E_L_E_T_ 		= ' '"
				_cQry += " AND SF2.F2_ESPECIE 		= 'SPED'"
				_cQry += " AND SF2.F2_SERIE||SF2.F2_DOC = NFE_ID"
				_cQry += " AND F2_FIMP 				= 'T'"
				_cQry += " AND F2_FILIAL 			= '" + _aEmpresas[_ixe,04] + "'"
				_cQry += " AND SPD050.AMBIENTE 		= '" + _aEmpresas[_ixe,05] +"'"
				_cQry += " AND SPD050.MODALIDADE 	= '" + _aEmpresas[_ixe,06] +"'"
				_cQry += " AND SPD050.STATUS 		= 6"
				_cQry += " AND SF2.F2_SERIE 		= '"+QRYNFCF->F2_SERIE+"'"
				_cQry += " AND SF2.F2_DOC 			= '"+QRYNFCF->F2_DOC+"'"

				_cQry := Changequery(_cQry)
				TCQUERY _cQry NEW ALIAS "SPDX"

				// abre o dicionário SX1
				/*OpenSXs(NIL, NIL, NIL, NIL, cEmpAnt, cAliasSX1, "SX1", NIL, .F.)
				lOpen := Select(cAliasSX1) > 0

				// caso aberto, posiciona no topo
				If !(lOpen)
					Return .F.
				EndIf

				DbSelectArea(cAliasSX1)
				(cAliasSX1)->( DbSetOrder( 1 ) ) //X1_GRUPO+X1_ORDEM
				(cAliasSX1)->( DbGoTop() )
				(cAliasSX1)->( DbSeek("NFSIGW") )

				cMV_CH := Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) //verifica em qual MV_CH começa: 0 ou 1

				While !(cAliasSX1)->( Eof() ) .and. AllTrim((cAliasSX1)->&("X1_GRUPO")) == "NFSIGW"

					RecLock(cAliasSX1)

					If(cVersao == "11" .or. "TOTVS 2011" $ cVersao .or. cMV_CH == "MV_CH1")

						Do case
						Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH1"	// Da Nota Fiscal ?
							(cAliasSX1)->&("X1_CNT01") := Substr(SPDX->NFE_ID,4,9)
							MV_PAR01 := (cAliasSX1)->&("X1_CNT01")
						Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH2"	// Ate a Nota Fiscal ?
							(cAliasSX1)->&("X1_CNT01") := Substr(SPDX->NFE_ID,4,9)
							MV_PAR02 := (cAliasSX1)->&("X1_CNT01")
						Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH3"	// Da Serie ?
							(cAliasSX1)->&("X1_CNT01") := Left(SPDX->NFE_ID,3)
							MV_PAR03 := (cAliasSX1)->&("X1_CNT01")
						Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH4"	// Tipo de Operacao ? (1)Entrada / (2)Saida
							(cAliasSX1)->&("X1_CNT01") := "2"
							MV_PAR04 := 2
						Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH5"	// Imprime no verso?
							(cAliasSX1)->&("X1_CNT01") := "2"
							MV_PAR05 := 2
						Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH6"	// Danfe Simplificado?
							(cAliasSX1)->&("X1_CNT01") := ""
							MV_PAR06 := ""
						EndCase
					Else
						Do case
						Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH0"	// Da Nota Fiscal ?
							(cAliasSX1)->&("X1_CNT01") := Substr(SPDX->NFE_ID,4,9)
							MV_PAR01 := (cAliasSX1)->&("X1_CNT01")
						Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH1"	// Ate a Nota Fiscal ?
							(cAliasSX1)->&("X1_CNT01") := Substr(SPDX->NFE_ID,4,9)
							MV_PAR02 := (cAliasSX1)->&("X1_CNT01")
						Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH2"	// Da Serie ?
							(cAliasSX1)->&("X1_CNT01") := Left(SPDX->NFE_ID,3)
							MV_PAR03 := (cAliasSX1)->&("X1_CNT01")
						Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH3"	// Tipo de Operacao ? (1)Entrada / (2)Saida
							(cAliasSX1)->&("X1_CNT01") := "2"
							MV_PAR04 := 2
						Case Upper(AllTrim((cAliasSX1)->&("X1_VARIAVL"))) == "MV_CH4"	// Imprime no verso?
							(cAliasSX1)->&("X1_CNT01") := "2"
							MV_PAR05 := 2
						EndCase
					Endif

					(cAliasSX1)->( DbUnLock() )
					(cAliasSX1)->( DbCommit() )

					(cAliasSX1)->( DbSkip() )
				EndDo

				//Compatibiliza tamanho dos parâmetros
				MV_PAR01 := SubStr(QRYNFCF->F2_DOC,1,9)
				MV_PAR02 := SubStr(QRYNFCF->F2_DOC,1,9)
				MV_PAR03 := SubStr(QRYNFCF->F2_SERIE,1,3)
				*/

				Pergunte("NFSIGW",.F.)
				SetMVValue("NFSIGW","MV_PAR01",QRYNFCF->F2_DOC) // Da Nota Fiscal ?
				SetMVValue("NFSIGW","MV_PAR02",QRYNFCF->F2_DOC) // Ate a Nota Fiscal ?
				SetMVValue("NFSIGW","MV_PAR03",QRYNFCF->F2_SERIE) // Da Serie ?
				SetMVValue("NFSIGW","MV_PAR04",2) //Tipo de Operacao ? (1)Entrada / (2)Saida
				SetMVValue("NFSIGW","MV_PAR07",QRYNFCF->F2_EMISSAO) //data emissao de
				SetMVValue("NFSIGW","MV_PAR08",QRYNFCF->F2_EMISSAO) //data emissao ate
				Pergunte("NFSIGW",.F.) 

				cFilePrint	:= QRYNFCF->F2_CHVNFE
				//cDirDanfe	:= Alltrim(SuperGetMV( "MV_XDIRDAN" , .T./*lHelp*/, "arquivos_mo\danfes\" /*cPadrao*/))
				//oSetup		:= FWPrintSetup():New(nFlags,"Impressão Auto Boleto/DANFE")
				oBjNfe		:= FWMSPrinter():New(cFilePrint /*Nome Arq*/, IMP_PDF /*IMP_SPOOL/IMP_PDF*/, .F. /*3-Legado*/,;
							/*4-Dir. Salvar*/, .T. /*5-Não Exibe Setup*/, /*6-Classe TReport*/,;
					oSetup /*7-oPrintSetup*/, ""  /*8-Impressora Forçada*/,;
					.F. /*lServer*/ )

				oBjNfe:SetResolution(78) //Tamanho estipulado para a Danfe
				oBjNfe:SetPortrait()
				oBjNfe:SetPaperSize(DMPAPER_A4)
				oBjNfe:nDevice := IMP_SPOOL

				//-- WriteProfString:  deprecated - descontinuada
				// Cria ou altera o conteúdo de uma chave no arquivo win.ini (arquivo utilizado para armazenar configurações básicas de inicialização) do sistema operacional.
				WriteProfString(GetPrinterSession(),"DEFAULT", aImp[1] /*oSetup:aOptions[PD_VALUETYPE]*/, .T.)
				
				oBjNfe:cPrinter := aImp[1]

				u_PrtNfeSef(_aEmpresas[_ixe,01], "", "", oBjNfe, /*oSetup*/, cFilePrint) //Rdmake de exemplo para impressão da DANFE no formato Retrato

				lRet := .T.

				SPDX->( DbCloseArea() )
			Endif

			QRYNF->(DbSkip())
		EndDo
	Endif

	If !lRet
		If AllTrim(FunName()) == "RFATE001"
			MsgInfo("O Título "+AllTrim(cNumero)+" não possui DANFE autorizado/relacionado!!","Atenção")
		Else
			MsgInfo("O Cupom Fiscal "+AllTrim(cNumero)+" não possui DANFE autorizado/relacionado!!","Atenção")
		Endif
	Endif

Return
