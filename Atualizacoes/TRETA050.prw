#Include "PROTHEUS.CH"
#Include "Topconn.ch"

Static lExistUI3 := .F.

/*/{Protheus.doc} TRETA050
Tela de Dados Complementares Consolidado.
@author Totvs GO
@since 23/02/2021
@version 1.0
@param cCod, characters, descricao
@param cOri, characters, descricao

@type function
/*/
User Function TRETA050(cCod,cOri)

	Local aArea 	:= GetArea()
	Local aAreaSA1  := SA1->( GetArea() )
	Local aAreaUI3

	Private _MSG	 := {| cStr | oSay:cCaption := (cStr) , ProcessMessages() }

	lExistUI3 := ChkFile("UI3")

	If lExistUI3
		aAreaUI3 := UI3->( GetArea() )
		FWMsgRun(,{|oSay|VerUI3(cCod)},"Dados Complementares Consolidados","Verificando Cadastro | Aguarde...")
	EndIf
	FWMsgRun(,{|oSay|Tela(@oSay,cCod,cOri)},"Dados Complementares Consolidados","Carregando Informações | Aguarde...")

	RestArea( aAreaSA1 )
	If lExistUI3
		RestArea( aAreaUI3 )
	EndIf
	RestArea( aArea )

Return

/*/{Protheus.doc} VerUI3
Inclui registro UI3, caso não exista...

@type function
@version 1
@author pablo
@since 23/02/2021
@param cCod, character, código do produto
/*/
Static Function VerUI3(cCod)

	Local aUI3		:= {}
	Local cGrupo	:= ""
	Local lContinua	:= .F.
	Local cQry		:= ""

	DbSelectArea("SA1")
	DbSelectArea("UI3")

	// Primeiro valida se o cliente passado por parametro, possue grupo, lembrando que olhamos todas as lojas do mesmo código (Éder).
	cQry := " SELECT * FROM " + RetSqlName("SA1") + " SA1 "
	cQry += " WHERE SA1.D_E_L_E_T_ = ' ' "
	cQry += " AND SA1.A1_COD = '" + cCod + "' "
	cQry := ChangeQuery(cQry)

	If Select("QSA1") > 0
		QSA1->( DbCloseArea() )
	EndIf

	TcQuery cQry New Alias "QSA1"

	While QSA1->( !EOF() )
		If !Empty(AllTrim(QSA1->A1_GRPVEN))
			If Empty(AllTrim(cGrupo))
				cGrupo := "'" + QSA1->A1_GRPVEN	+ "'"
			Else
				cGrupo += ",'" + QSA1->A1_GRPVEN + "'"
			EndIf
		EndIf
		QSA1->( DbSkip() )
	EndDo

	// Se encontramos grupos na consulta acima, entao filtraremos todos os clientes a partir dos grupos que encontramos, senão, continua com a mesma consulta.
	If !Empty(AllTrim(cGrupo))
		cQry := " SELECT * FROM " + RetSqlName("SA1") + " SA1 "
		cQry += " WHERE SA1.D_E_L_E_T_ = ' ' "
		cQry += " AND SA1.A1_GRPVEN IN (" + cGrupo + ") "
		cQry := ChangeQuery(cQry)

		If Select("QSA1") > 0
			QSA1->( DbCloseArea() )
		EndIf

		TcQuery cQry New Alias "QSA1"
	Else
		QSA1->( DbGoTop() )
	EndIf

	// Com os registros prontos, faz a consulta se existe na UI3, senão, cria.
	While QSA1->( !EOF() )

		lContinua := .F.

		UI3->( DbSetOrder(1) ) //UI3_FILIAL + UI3_COD + UI3_LOJA
		If !UI3->( DbSeek( xFilial("UI3")+QSA1->A1_COD+QSA1->A1_LOJA ) )
			lContinua := .T.
		EndIf

		If lContinua //inclui UI3
			If SA1->( DbSetOrder(1), MsSeek(xFilial("SA1")+QSA1->A1_COD+QSA1->A1_LOJA) )
				//Aba Cadastrais
				aAdd(aUI3, {'UI3_COD'    , QSA1->A1_COD } )
				aAdd(aUI3, {'UI3_LOJA'   , QSA1->A1_LOJA} )
				//Aba Bloqueios
				//aAdd(aUI3, {'UI3_MBLQL'  , 'N' } )
				//aAdd(aUI3, {"UI3_BLQPDV" , 'S' } ) 	//Bloqueio de venda pdV - bloqueio de credito (1=Sim;2=Nao)
				//aAdd(aUI3, {"UI3_BLQCR"  , 'S' } )	//Bloqueio de Título Recebido (1=Sim,2=Não)
				aAdd(aUI3, {"UI3_EMICHQ" , /*'N'*/ SubStr(GetSx3Cache("UI3_EMICHQ","X3_RELACAO"),2,1) } ) 	//Emitente de Cheque (S/N)
				//aAdd(aUI3, {"UI3_BLQCHQ" , 'S' } )	//Bloqueado para emissão de cheque (S/N)
				//aAdd(aUI3, {"UI3_BLQRS"  , 'S' } )	//Bloqueio Requisição de Saque (1=Sim,2=Não)
				//aAdd(aUI3, {"UI3_BLQRC"  , 'S' } )	//Bloqueio Rq. Comp. (S=Sim,N=Não)
				aAdd(aUI3, {"UI3_EMITCF" , 'N' } ) 	//Emite carta frete (sim ou não)
				//aAdd(aUI3, {"UI3_BLQCF"  , 'S' } )	//Bloqueio CF (S=Sim,N=Não)
				//Aba Limites e Saldos
				aAdd(aUI3, {"UI3_LC"	 , 0   } )	//Limite de credito global (à prazo incluso cheque)
				aAdd(aUI3, {"UI3_LCCR"	 , 0   } ) 	//Limite de credito de titulos a receber (à praso menos cheque)
				aAdd(aUI3, {"UI3_LCCHQ"	 , 0   } ) 	//Limite de cheque
				aAdd(aUI3, {"UI3_LCQCH"	 , 0   } )	//Quantidade de cheques (numero maximo de cheque a prazo que o cliente pode emitir) //Num. Cheques Abertos (Numerico 3 caracter)
				aAdd(aUI3, {"UI3_LCRC"   , 0   } ) 	//Limite de credito consumo
				aAdd(aUI3, {"UI3_LCRS"   , 0   } ) 	//Limite de credito de saque
				aAdd(aUI3, {"UI3_LIMCF"  , 0   } ) 	//Limite de credito de carta frete
				If FindFunction('U_ULOJA125')
					U_ULOJA125(aUI3,3) // Rotina que inclui UI3
				EndIf
			EndIf
		EndIf

		QSA1->( DbSkip() )
	EndDo

Return

/*/{Protheus.doc} Tela
Tela de dados consolidados
@type function
@version 1
@author pablo
@since 24/02/2021
@param oSay, object, objeto de processa as mensagens
@param cCod, character, código do cliente
@param cOri, character, tabela de origem (SA1 ou ACY)
/*/
Static Function Tela(oSay,cCod,cOri)
	
	Local nLin := 0
	Local aFolders := Iif(lExistUI3,{"Limites/Saldos","Bloqueios","Resumo Serasa"},{"Limites/Saldos","Bloqueios"})

	Private oDlgDado
	Private oGroup1
	Private oGroup2
	Private oGroup3
	Private oGroup4
	Private oGroup5
	Private oFolder1
	Private cCliente := cCod
	Private cOrigem	:= cOri //"SA1" ou "ACY"
	Private oMSNewGe1
	Private oMSNewGe2
	Private oMSNewGe3
	Private oMSNewGe4
	Private oMSNewGe5
	Private loMSNewGe1 := .T.
	Private loMSNewGe2 := .T.
	Private loMSNewGe3 := .T.
	Private loMSNewGe4 := .T.
	Private loMSNewGe5 := .T.
	Private lMotivo := .F.
	Private _cMotivo := ""
	Private aMotivo := {}

	Private aColsEx1 := {}
	Private aColsEx2 := {}
	Private aColsEx3 := {}
	Private aColsEx4 := {}
	Private aColsEx5 := {}

	Private aObjects := {}
	Private aSizeAut := MsAdvSize()
	Private aPosObj  := {}

	Public _QualObj

	INCLUI := .F.
	ALTERA := .T.

//Largura, Altura, Modifica largura, Modifica altura
	aAdd(aObjects,{100,050,.T.,.T.}) //cabeçalho
	aAdd(aObjects,{100,050,.T.,.T.}) //grid
	//aAdd(aObjects,{100,15,.T.,.T.}) //Rodapé

	aInfo 	:= { aSizeAut[ 1 ], aSizeAut[ 2 ], aSizeAut[ 3 ], aSizeAut[ 4 ], 3, 3 }
	aPosObj := MsObjSize( aInfo, aObjects, .T. ) //LINHA(TOP) COLUNA(LEFT) LARGURA(WIDTH) ALTURA(HEIGHT)

	DEFINE MSDIALOG oDlgDado TITLE "Dados Complementares" FROM aSizeAut[7], 000  TO aSizeAut[6], aSizeAut[5] COLORS 0, 16777215 OF oMainWnd PIXEL
	//@ C(002), C(002) FOLDER oFolder1 SIZE C(496), C(218) OF oDlgDado ITEMS "Limites/Saldos","Bloqueios","Resumo Serasa" COLORS 0, 16777215 PIXEL
	oFolder1 := TFolder():New( aSizeAut[2]-30,aSizeAut[1],aFolders,,oDlgDado,,,,.T.,,aSizeAut[3],aSizeAut[4] )
	
	nLin := aPosObj[1,1]-30
	// Pasta Limites/Saldos
	@ aPosObj[1,1]-30, aPosObj[1,2] GROUP oGroup1 TO aPosObj[1,3]-30, aPosObj[1,4]-75 PROMPT "Por Lojas" OF oFolder1:aDialogs[1] COLOR 0, 16777215 PIXEL
	@ aPosObj[2,1]-30, aPosObj[2,2] GROUP oGroup2 TO aPosObj[2,3]-30, aPosObj[2,4]-75 PROMPT "Por Grupo" OF oFolder1:aDialogs[1] COLOR 0, 16777215 PIXEL
	@ C(nLin+=6) , aPosObj[1,4]-70 BUTTON oButton1 PROMPT "Confirmar" SIZE C(043), C(019) OF oFolder1:aDialogs[1] PIXEL ACTION (FWMsgRun(,{|oSay|Confirma(@oSay)},"TOTVS","Aguarde..."))
	@ C(nLin+=24), aPosObj[1,4]-70 BUTTON oButton2 PROMPT "Sair" SIZE C(043), C(019) OF oFolder1:aDialogs[1] PIXEL ACTION (oDlgDado:End())
	If lExistUI3
		@ C(nLin+=24), aPosObj[1,4]-70 BUTTON oButton3 PROMPT "Cruzar Dados" SIZE C(043), C(019) OF oFolder1:aDialogs[1] PIXEL ACTION (FWMsgRun(,{|oSay|CruzaDados(1,@oSay)},"TOTVS","Aguarde..."))
		@ C(nLin+=24), aPosObj[1,4]-70 BUTTON oButton4 PROMPT "Consulta Serasa" SIZE C(043), C(019) OF oFolder1:aDialogs[1] PIXEL ACTION (CallSerasa(1))
	EndIf
	@ C(nLin+=24), aPosObj[1,4]-70 BUTTON oButton5 PROMPT "Grupo de Clientes" SIZE C(043), C(019) OF oFolder1:aDialogs[1] PIXEL ACTION (FATA110())
	
	nLin := aPosObj[1,1]-30
	// Pasta Bloqueios
	@ aPosObj[1,1]-30, aPosObj[1,2] GROUP oGroup3 TO aPosObj[1,3]-30, aPosObj[1,4]-75 PROMPT "Por Lojas" OF oFolder1:aDialogs[2] COLOR 0, 16777215 PIXEL
	@ aPosObj[2,1]-30, aPosObj[2,2] GROUP oGroup4 TO aPosObj[2,3]-30, aPosObj[2,4]-75 PROMPT "Por Grupo" OF oFolder1:aDialogs[2] COLOR 0, 16777215 PIXEL
	@ C(nLin+=6),  aPosObj[1,4]-70 BUTTON oButton1 PROMPT "Confirmar" SIZE C(043), C(019) OF oFolder1:aDialogs[2] PIXEL ACTION (FWMsgRun(,{|oSay|Confirma(@oSay)},"TOTVS","Aguarde..." ))
	@ C(nLin+=24), aPosObj[1,4]-70 BUTTON oButton2 PROMPT "Sair" SIZE C(043), C(019) OF oFolder1:aDialogs[2] PIXEL ACTION (oDlgDado:End())
	If lExistUI3
		@ C(nLin+=24), aPosObj[1,4]-70 BUTTON oButton3 PROMPT "Cruzar Dados" SIZE C(043), C(019) OF oFolder1:aDialogs[2] PIXEL ACTION (FWMsgRun(,{|oSay|CruzaDados(2,@oSay)},"TOTVS","Aguarde..."))
		@ C(nLin+=24), aPosObj[1,4]-70 BUTTON oButton4 PROMPT "Consulta Serasa" SIZE C(043), C(019) OF oFolder1:aDialogs[2] PIXEL ACTION (CallSerasa(2))
	EndIf
	@ C(nLin+=24), aPosObj[1,4]-70 BUTTON oButton5 PROMPT "Grupo de Clientes" SIZE C(043), C(019) OF oFolder1:aDialogs[2] PIXEL ACTION (FATA110())

	nLin := aPosObj[1,1]-30
	// Pasta Resumo Serasa
	If lExistUI3
		@ aPosObj[1,1]-30, aPosObj[1,2] GROUP oGroup5 TO aPosObj[2,3]-30,aPosObj[2,4]-75 PROMPT "Por Lojas" OF oFolder1:aDialogs[3] COLOR 0, 16777215 PIXEL
//	    @ C(102), C(000) GROUP oGroup4 TO C(202), C(445) PROMPT "Por Grupo" OF oFolder1:aDialogs[3] COLOR 0, 16777215 PIXEL
		@ C(nLin+=6),  aPosObj[1,4]-70 BUTTON oButton1 PROMPT "Confirmar" SIZE C(043), C(019) OF oFolder1:aDialogs[3] PIXEL ACTION (FWMsgRun(,{|oSay|Confirma(@oSay)},"TOTVS","Aguarde..." ))
		@ C(nLin+=24), aPosObj[1,4]-70 BUTTON oButton2 PROMPT "Sair" SIZE C(043), C(019) OF oFolder1:aDialogs[3] PIXEL ACTION (oDlgDado:End())
		@ C(nLin+=24), aPosObj[1,4]-70 BUTTON oButton3 PROMPT "Cruzar Dados" SIZE C(043), C(019) OF oFolder1:aDialogs[3] PIXEL ACTION (FWMsgRun(,{|oSay|CruzaDados(3,@oSay)},"TOTVS","Aguarde..."))
		@ C(nLin+=24), aPosObj[1,4]-70 BUTTON oButton4 PROMPT "Consulta Serasa" SIZE C(043), C(019) OF oFolder1:aDialogs[3] PIXEL ACTION (CallSerasa(3))
		@ C(nLin+=24), aPosObj[1,4]-70 BUTTON oButton5 PROMPT "Grupo de Clientes" SIZE C(043), C(019) OF oFolder1:aDialogs[3] PIXEL ACTION (FATA110())
	EndIf

	LoadGrid()

	ACTIVATE MSDIALOG oDlgDado CENTERED

Return

//------------------------------------------------
Static Function LoadGrid()
//------------------------------------------------

	fMSNewGe1()
	fMSNewGe2()
	fMSNewGe3()
	fMSNewGe4()
	If lExistUI3
		fMSNewGe5()
	EndIf

Return

//------------------------------------------------
Static Function fMSNewGe1() //limite cliente
//------------------------------------------------
	Local cQry	:= ""
	Local cGrupo := ""
	Local nX
	Local aHeaderEx := {}
	Local aFields := {  "A1_FILIAL", "A1_COD", "A1_LOJA", "A1_NOME", "A1_NREDUZ", "A1_XRISCO", "A1_GRPVEN",;
		"A1_XCOMERC", "A1_XOPCOBR",;
		"A1_XLC"    , "A1_XSLDLC" ,;
		"A1_XLIMSQ" , "A1_XSLDSQ" }

	Local aAlterFields := {"A1_XRISCO","A1_XOPCOBR","A1_XCOMERC","A1_XLC","A1_XLIMSQ"}
	Local aCpoEdit := {}
	Local nI

	If FindFunction("U_APMR00D") //Verifica se há bloqueio de edição de campos (específico Marajo)
		aAlterFields	:= {}
		aCpoEdit 		:= {"A1_XRISCO","A1_XOPCOBR","A1_XCOMERC","A1_XLC","A1_XLIMSQ"}
		For nI := 1 To Len(aCpoEdit)
			If U_APMR00D(aCpoEdit[nI])
				AAdd(aAlterFields,aCpoEdit[nI])
			Endif
		Next nI
	Endif

	// Define field properties
	For nX:=1 to Len(aFields)
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	Next nX

	// Define field values
	// Verifica se o cliente tem grupo amarrado, pra trazer todos os clientes amarrados ao mesmo grupo
	If cOrigem == "SA1" //"SA1" ou "ACY"
		cQry := " SELECT SA1.A1_GRPVEN FROM "+RetSqlName("SA1")+" SA1 WHERE SA1.D_E_L_E_T_ = ' ' AND SA1.A1_COD ='" + AllTrim(cCliente) + "'"
		cQry := ChangeQuery(cQry)

		If Select("QRY1") > 0
			QRY1->( DbCloseArea() )
		EndIf

		TcQuery cQry New Alias "QRY1"
		QRY1->( DbGoTop() )

		While QRY1->(!Eof())
			cGrupo += AllTrim(QRY1->A1_GRPVEN)
			QRY1->(DbSkip())
		EndDo
	EndIf

	If cOrigem == "SA1" //"SA1" ou "ACY"
		If !Empty(AllTrim(cGrupo)) //por grupo
			cQry := " SELECT * FROM " + RetSqlName("SA1") + " SA1"
			If lExistUI3
				cQry := " SELECT ISNULL(CONVERT(VARCHAR(1024),CONVERT(VARBINARY(1024),UI3_HISTOR)),'') AS UI3_HISTOR, SA1.*, UI3.* FROM " + RetSqlName("SA1") + " SA1"
				cQry += " INNER JOIN " + RetSqlName("UI3") + " UI3 ON "
				cQry += " (SA1.A1_FILIAL = UI3.UI3_FILIAL AND SA1.A1_COD = UI3.UI3_COD AND UI3.UI3_LOJA = SA1.A1_LOJA AND SA1.D_E_L_E_T_ = ' ')"
			EndIf
			cQry += " WHERE SA1.D_E_L_E_T_ = ' ' AND RTRIM(SA1.A1_COD) IN ("
			cQry += " SELECT DISTINCT RTRIM(SA1.A1_COD) FROM " + RetSqlName("SA1") + " SA1 WHERE D_E_L_E_T_ = ' ' AND SA1.A1_GRPVEN IN "
			cQry +=     " (SELECT SA1.A1_GRPVEN FROM "+RetSqlName("SA1")+" SA1 WHERE D_E_L_E_T_ = ' ' AND SA1.A1_COD ='" + AllTrim(cCliente) + "' "
			cQry +=     "  AND SA1.A1_GRPVEN <> ' ' ) "
			cQry += " ) "
			cQry += " ORDER BY SA1.A1_COD, SA1.A1_LOJA ASC "
		Else //código de cliente
			cQry := " SELECT * FROM " + RetSqlName("SA1") + " SA1"
			If lExistUI3
				cQry := " SELECT ISNULL(CONVERT(VARCHAR(1024),CONVERT(VARBINARY(1024),UI3_HISTOR)),'') AS UI3_HISTOR, SA1.*, UI3.* FROM " + RetSqlName("SA1") + " SA1"
				cQry += " INNER JOIN " + RetSqlName("UI3") + " UI3 ON "
				cQry += " (SA1.A1_FILIAL = UI3.UI3_FILIAL AND SA1.A1_COD = UI3.UI3_COD AND UI3.UI3_LOJA = SA1.A1_LOJA AND SA1.D_E_L_E_T_ = ' ')"
			EndIf
			cQry += " WHERE SA1.D_E_L_E_T_ = ' ' AND RTRIM(SA1.A1_COD)  = '" + AllTrim(cCliente) + "' "
			cQry += " ORDER BY SA1.A1_COD, SA1.A1_LOJA ASC"
		EndIf
	Else
		cQry := " SELECT * FROM " + RetSqlName("SA1") + " SA1"
		If lExistUI3
			cQry := " SELECT ISNULL(CONVERT(VARCHAR(1024),CONVERT(VARBINARY(1024),UI3_HISTOR)),'') AS UI3_HISTOR, SA1.*, UI3.* FROM " + RetSqlName("SA1") + " SA1"
			cQry += " INNER JOIN " + RetSqlName("UI3") + " UI3 ON "
			cQry += " (SA1.A1_FILIAL = UI3.UI3_FILIAL AND SA1.A1_COD = UI3.UI3_COD AND UI3.UI3_LOJA = SA1.A1_LOJA AND SA1.D_E_L_E_T_ = ' ')"
		EndIf
		cQry += " WHERE SA1.D_E_L_E_T_ = ' ' AND RTRIM(SA1.A1_COD) IN "
		cQry += " (SELECT DISTINCT RTRIM(A1_COD) FROM "+RetSqlName("SA1")+" WHERE D_E_L_E_T_ = ' ' AND A1_GRPVEN = '" + AllTrim(cCliente) + "')"
		cQry += " ORDER BY SA1.A1_COD, SA1.A1_LOJA ASC"
	EndIf

	If Select("QRY1") > 0
		QRY1->( DbCloseArea() )
	EndIf
	
	cQry := ChangeQuery(cQry)

	TcQuery cQry New Alias "QRY1"
	QRY1->( DbGoTop() )

	If QRY1->(Eof())
		loMsNewGe1 := .F.
		Return
	EndIf

	aColsEx1 := {}
	aColsEx3 := {}
	aColsEx5 := {}

	SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
	While QRY1->(!Eof())

		SA1->(DbSeek(xFilial("SA1")+QRY1->A1_COD+QRY1->A1_LOJA))
		aTemp := {}
		For nX:=1 to Len(aHeaderEx)
			If aHeaderEx[nX][10] == "V" //se virtual
				Aadd(aTemp, &(aHeaderEx[nX][12])) //inicializador padrão (X3_RELACAO)
			Else
				Aadd(aTemp, QRY1->&(aHeaderEx[nX][2]))
			EndIf
		Next nX
		Aadd(aTemp,.F.)
		Aadd(aColsEx1,aTemp)

		If lExistUI3
			Aadd(aColsEx5,{	QRY1->A1_FILIAL, QRY1->A1_COD, QRY1->A1_LOJA, QRY1->A1_NOME, QRY1->A1_NREDUZ,+;
				QRY1->UI3_DTABER	,QRY1->UI3_VLRCS 	,QRY1->UI3_QTCHSF	,QRY1->UI3_VLCHSF,+;
				QRY1->UI3_QTREFI	,QRY1->UI3_VLREFI	,QRY1->UI3_QTPEFI	,QRY1->UI3_VLPEFI,+;
				QRY1->UI3_QTDPRT 	,QRY1->UI3_VLPRT 	,.F.})
		EndIf

		Aadd(aMotivo,{.F.,QRY1->A1_COD+QRY1->A1_LOJA})

		QRY1->( DbSkip() )
	EndDo

	If Type("oMSNewGe1") == "U"
		oMSNewGe1 := MsNewGetDados():New( C(007), C(005), C(095), aSizeAut[6]-25, GD_INSERT+GD_DELETE+GD_UPDATE, 'AllwaysTrue', "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "u_TRETA50A()", "", "AllwaysTrue", oGroup1, aHeaderEx, aColsEx1)
		oMSNewGe1:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	Else
		oMSNewGe1:SetArray(aColsEx1)
		oMSNewGe1:Refresh(.T.)
		oMSNewGe1:ForceRefresh()
	EndIF
	oMSNewGe1:lDelete := .F.
	oMSNewGe1:lInsert := .F.

Return

//------------------------------------------------------
Static Function fMSNewGe2() //limite grupo de cliente
//------------------------------------------------------
	Local nX
	Local aHeaderEx := {}
	Local aFields := {"ACY_FILIAL"	,"ACY_GRPVEN"	,"ACY_DESCRI"	,;
		"ACY_XLC"		,"ACY_XSLDLC"	,;
		"ACY_XLIMSQ"	,"ACY_XSLDSQ"	}

	Local aAlterFields := {"ACY_XLC","ACY_XLIMSQ"}
	Local aCpoEdit := {}
	Local nI

	If FindFunction("U_APMR00D") //Verifica se há bloqueio de edição de campos (específico Marajo)
		aAlterFields	:= {}
		aCpoEdit 		:= {"ACY_XLC","ACY_XLIMSQ"}
		For nI := 1 To Len(aCpoEdit)
			If U_APMR00D(aCpoEdit[nI])
				AAdd(aAlterFields,aCpoEdit[nI])
			Endif
		Next nI
	Endif

	// Define field properties
	For nX:=1 to Len(aFields)
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	Next nX

	// Define field values
	cQry := " SELECT * FROM " + RetSqlName("ACY") + " ACY"
	cQry += " WHERE ACY.D_E_L_E_T_ = ' ' AND ACY.ACY_GRPVEN IN "
	If cOrigem == "SA1" //"SA1" ou "ACY"
		cQry += " (SELECT SA1.A1_GRPVEN FROM "+RetSqlName("SA1")+" SA1 WHERE D_E_L_E_T_ = ' ' AND SA1.A1_COD ='" + AllTrim(cCliente) + "') "
	Else
		cQry += " ('" + AllTrim(cCliente) + "') "
	EndIf
	cQry += " ORDER BY ACY.ACY_GRPVEN ASC"
	cQry := ChangeQuery(cQry)

	If Select("QRY2") > 0
		QRY2->( DbCloseArea() )
	EndIf

	TcQuery cQry New Alias "QRY2"
	QRY2->( DbGoTop() )

	If QRY2->(Eof())
		loMSNewGe2 := .F.
		Return
	EndIf

	aColsEx2 := {}
	aColsEx4 := {}

	ACY->(DbSetOrder(1)) //ACY_FILIAL+ACY_GRPVEN
	While QRY2->(!Eof())

		ACY->(DbSeek(xFilial("ACY")+QRY2->ACY_GRPVEN))
		aTemp := {}
		For nX:=1 to Len(aHeaderEx)
			If aHeaderEx[nX][10] == "V" //se virtual
				Aadd(aTemp, &(aHeaderEx[nX][12])) //inicializador padrão (X3_RELACAO)
			Else
				Aadd(aTemp, QRY2->&(aHeaderEx[nX][2]))
			EndIf
		Next nX
		Aadd(aTemp,.F.)
		Aadd(aColsEx2,aTemp)

		QRY2->( DbSkip() )
	EndDo

	If Type("oMSNewGe2") == "U"
		oMSNewGe2 := MsNewGetDados():New( C(109), C(005), C(199), aSizeAut[6]-25, GD_INSERT+GD_DELETE+GD_UPDATE, 'AllwaysTrue', "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "u_TRETA50A()", "", "AllwaysTrue", oGroup2, aHeaderEx, aColsEx2)
		oMSNewGe2:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	Else
		oMSNewGe2:SetArray(aColsEx2)
		oMSNewGe2:Refresh(.T.)
		oMSNewGe2:ForceRefresh()
	EndIf

Return

//------------------------------------------------
Static Function fMSNewGe3() //bloqueio cliente
//------------------------------------------------
	Local nX
	Local aHeaderEx := {}
	Local aFields := {"A1_FILIAL","A1_COD","A1_LOJA","A1_NOME","A1_NREDUZ","A1_GRPVEN","A1_MSBLQL","A1_XBLQLC","A1_XBLQSQ",;
		"A1_XTIPONF","A1_XODOMET","A1_XMOTOR","A1_XFROTA","A1_XRESTRI","A1_XCONDSA","A1_XEMCHQ","A1_XEMICF","A1_XVLSPOS","A1_XCDVLSP","A1_XFILBLQ"}
	Local aAlterFields := {"A1_GRPVEN","A1_MSBLQL","A1_XBLQLC","A1_XBLQSQ",;
		"A1_XTIPONF","A1_XODOMET","A1_XMOTOR","A1_XFROTA","A1_XRESTRI","A1_XCONDSA","A1_XEMCHQ","A1_XEMICF","A1_XVLSPOS","A1_XCDVLSP","A1_XFILBLQ"}
	Local aCpoEdit := {}
	Local nI

	If lExistUI3
		Aadd(aFields, "UI3_HISTOR")
		Aadd(aAlterFields, "UI3_HISTOR")
	EndIf

	If FindFunction("U_APMR00D") //Verifica se há bloqueio de edição de campos (específico Marajo)
		aAlterFields	:= {}
		aCpoEdit 		:= {"A1_GRPVEN","A1_MSBLQL","A1_XBLQLC","A1_XBLQSQ",;
			"A1_XTIPONF","A1_XODOMET","A1_XMOTOR","A1_XFROTA","A1_XRESTRI","A1_XCONDSA","A1_XEMCHQ","A1_XEMICF","A1_XVLSPOS","A1_XCDVLSP","A1_XFILBLQ"}
		For nI := 1 To Len(aCpoEdit)
			If U_APMR00D(aCpoEdit[nI])
				AAdd(aAlterFields,aCpoEdit[nI])
			Endif
		Next nI
		If lExistUI3
			AAdd(aAlterFields,"UI3_HISTOR")
		EndIf
	Endif

	// Define field properties
	For nX:=1 to Len(aFields)
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	Next nX

	QRY1->( DbGoTop() )
	If QRY1->(Eof())
		loMSNewGe3 := .F.
		Return
	EndIf

	SA1->(DbSetOrder(1)) //A1_FILIAL+A1_COD+A1_LOJA
	While QRY1->(!Eof())

		SA1->(DbSeek(xFilial("SA1")+QRY1->A1_COD+QRY1->A1_LOJA))
		aTemp := {}
		For nX:=1 to Len(aHeaderEx)
			If aHeaderEx[nX][10] == "V" //se virtual
				Aadd(aTemp, &(aHeaderEx[nX][12])) //inicializador padrão (X3_RELACAO)
			Else
				Aadd(aTemp, QRY1->&(aHeaderEx[nX][2]))
			EndIf
		Next nX
		Aadd(aTemp,.F.)
		Aadd(aColsEx3,aTemp)

		QRY1->( DbSkip() )
	EndDo

	If Len(aColsEx3) == 0
		loMSNewGe3 := .F.
		Return
	EndIf

	If Type("oMSNewGe3") == "U"
		oMSNewGe3 := MsNewGetDados():New( C(007), C(005), C(095), aSizeAut[6]-25, GD_INSERT+GD_DELETE+GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "u_TRETA50A()", "", "AllwaysTrue", oGroup3, aHeaderEx, aColsEx3)
		oMSNewGe3:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	Else
		oMSNewGe3:SetArray(aColsEx3)
		oMSNewGe3:Refresh(.T.)
		oMSNewGe3:ForceRefresh()
	EndIf

	QRY1->( DbCloseArea() )

Return

//---------------------------------------------------------
Static Function fMSNewGe4() //bloqueio de grupo de cliente
//---------------------------------------------------------
	Local nX
	Local aHeaderEx := {}
	Local aFields := {"ACY_FILIAL","ACY_GRPVEN","ACY_DESCRI","ACY_XBLPRZ","ACY_XBLRSA"}
	Local aAlterFields := {"ACY_XBLPRZ","ACY_XBLRSA"}
	Local aCpoEdit := {}
	Local nI

	If FindFunction("U_APMR00D") //Verifica se há bloqueio de edição de campos (específico Marajo)
		aAlterFields	:= {}
		aCpoEdit 		:= {"ACY_XBLPRZ","ACY_XBLRSA"}
		For nI := 1 To Len(aCpoEdit)
			If U_APMR00D(aCpoEdit[nI])
				AAdd(aAlterFields,aCpoEdit[nI])
			Endif
		Next nI
	Endif

	// Define field properties
	For nX:=1 to Len(aFields)
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	Next nX

	QRY2->( DbGoTop() )
	If QRY2->(Eof())
		loMSNewGe4 := .F.
		Return
	EndIf

	ACY->(DbSetOrder(1)) //ACY_FILIAL+ACY_GRPVEN
	While QRY2->(!Eof())

		ACY->(DbSeek(xFilial("ACY")+QRY2->ACY_GRPVEN))
		aTemp := {}
		For nX:=1 to Len(aHeaderEx)
			If aHeaderEx[nX][10] == "V" //se virtual
				Aadd(aTemp, &(aHeaderEx[nX][12])) //inicializador padrão (X3_RELACAO)
			Else
				Aadd(aTemp, QRY2->&(aHeaderEx[nX][2]))
			EndIf
		Next nX
		Aadd(aTemp,.F.)
		Aadd(aColsEx4,aTemp)

		QRY2->( DbSkip() )
	EndDo

	If Len(aColsEx4) == 0
		loMSNewGe4 := .F.
		Return
	EndIf

	If Type("oMSNewGe4") == "U"
		oMSNewGe4 := MsNewGetDados():New( C(109), C(005), C(199), aSizeAut[6]-25, GD_INSERT+GD_DELETE+GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "u_TRETA50A()", "", "AllwaysTrue", oGroup4, aHeaderEx, aColsEx4)
		oMSNewGe4:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	Else
		oMSNewGe4:SetArray(aColsEx4)
		oMSNewGe4:Refresh(.T.)
		oMSNewGe4:ForceRefresh()
	EndIF

	QRY2->( DbCloseArea() )

Return

//------------------------------------------------
Static Function fMSNewGe5() //serasa
//------------------------------------------------
	Local nX
	Local aHeaderEx := {}
	Local aFields := {"A1_FILIAL","A1_COD","A1_LOJA","A1_NOME","A1_NREDUZ","UI3_DTABER","UI3_VLRCS","UI3_QTCHSF","UI3_VLCHSF","UI3_QTREFI","UI3_VLREFI","UI3_QTPEFI","UI3_VLPEFI","UI3_QTDPR","UI3_VLPRT"}
	Local aAlterFields := {""}

	// Define field properties
	For nX:=1 to Len(aFields)
		aadd(aHeaderEx, U_UAHEADER(aFields[nX]) )
	Next nX

	If Len(aColsEx5) == 0
		loMSNewGe5 := .F.
		Return
	EndIf

	If Type("oMSNewGe5") == "U"
		oMSNewGe5 := MsNewGetDados():New( C(007), C(005), C(095), aSizeAut[6]-25, GD_INSERT+GD_DELETE+GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "+Field1+Field2", aAlterFields,, 999, "u_TRETA50A()", "", "AllwaysTrue", oGroup5, aHeaderEx, aColsEx5)
		oMSNewGe5:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	Else
		oMSNewGe5:SetArray(aColsEx5)
		oMSNewGe5:Refresh(.T.)
		oMSNewGe5:ForceRefresh()
	EndIF

Return

//------------------------------------------------
Static Function Confirma(oSay)
//------------------------------------------------
	Local _cFilial	:= ""
	Local cCli 		:= ""
	Local cLoja     := ""
	Local xRet		:= .T.
	Local nX, nY

	If MsgYesNo("Tem certeza que deseja gravar as informações ?","Gravar Informações")

		If lMotivo // Houve bloqueio no grupo , entao gravo o motivo em todos os clientes.
			Motivo()
		Else // O motivo sera gravado apenas nos clientes que houveram alteração.
			For nX:=1 To Len(aMotivo)
				If aMotivo[nX][1]
					Motivo()
					Exit //sai do For nX
				EndIF
			Next nX
		EndIf

		If xRet
			Eval(_MSG,"Gravando Limites/Saldos")
			//Gravação dos Limites/Saldos das Lojas e do Grupo
			DbSelectArea("UI3")
			DbSetOrder(1)
			For nX:=1 To Len(oMsNewGe1:aCols)
				_cFilial := oMsNewGe1:aCols[nX][GdFieldPos("A1_FILIAL",oMsNewGe1:aHeader)]
				cCli  := oMsNewGe1:aCols[nX][GdFieldPos("A1_COD",oMsNewGe1:aHeader)]
				cLoja := oMsNewGe1:aCols[nX][GdFieldPos("A1_LOJA",oMsNewGe1:aHeader)]
				// Atualiza na UI3
				If lExistUI3 .and. UI3->( DbSeek(_cFilial+cCli+cLoja) )
					If RecLock("UI3", .F.)
						UI3->UI3_LC		:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XLC",oMsNewGe1:aHeader)]
						UI3->UI3_LCCR	:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XLC",oMsNewGe1:aHeader)]
						//UI3->UI3_LCCHQ	:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XLC",oMsNewGe1:aHeader)]
						//UI3->UI3_LCQCH	:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XLC",oMsNewGe1:aHeader)]
						//UI3->UI3_LCRC	:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XLC",oMsNewGe1:aHeader)]
						//UI3->UI3_LCRS	:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XLC",oMsNewGe1:aHeader)]
						//UI3->UI3_LIMCF	:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XLC",oMsNewGe1:aHeader)]
						//UI3->UI3_LCVLSP	:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XLC",oMsNewGe1:aHeader)]
						UI3->UI3_LCSQ	:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XLIMSQ",oMsNewGe1:aHeader)]
						UI3->( MsUnlock() )
					EndIf
				EndIf
				// Atualiza Saldo Global e Grau de Risco na SA1
				If SA1->(DbSetOrder(1), DbSeek(xFilial("SA1")+cCli+cLoja))
					If RecLock("SA1", .F.)
						SA1->A1_XRISCO 	:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XRISCO",oMsNewGe1:aHeader)]
						SA1->A1_XOPCOBR	:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XOPCOBR",oMsNewGe1:aHeader)]
						SA1->A1_XCOMERC	:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XCOMERC",oMsNewGe1:aHeader)]
						SA1->A1_LC 		:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XLC",oMsNewGe1:aHeader)]
						SA1->A1_XLC 	:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XLC",oMsNewGe1:aHeader)]
						SA1->A1_XLIMSQ	:= oMsNewGe1:aCols[nX][GdFieldPos("A1_XLIMSQ",oMsNewGe1:aHeader)]
						SA1->( MsUnlock() )
					EndIf
				EndIf
			Next nX

			If loMSNewGe2 .and. Type("oMsNewGe2") <> "U"
				DbSelectArea("ACY")
				DbSetOrder(1)
				For nX:=1 To Len(oMsNewGe2:aCols)
					_cFilial	:= oMsNewGe2:aCols[nX][GdFieldPos("ACY_FILIAL",oMsNewGe2:aHeader)]
					cCli		:= oMsNewGe2:aCols[nX][GdFieldPos("ACY_GRPVEN",oMsNewGe2:aHeader)]
					If ACY->( DbSeek(_cFilial+cCli) )
						If RecLock("ACY",.F.)
							ACY->ACY_XLC	:= oMsNewGe2:aCols[nX][GdFieldPos("ACY_XLC",oMsNewGe2:aHeader)]
							ACY->ACY_XLIMSQ	:= oMsNewGe2:aCols[nX][GdFieldPos("ACY_XLIMSQ",oMsNewGe2:aHeader)]
							ACY->( MsUnlock() )
						EndIf
					EndIF
				Next nX
			EndIf

			Eval(_MSG,"Gravando Bloqueios")
			//Grava os Bloqueios das Lojas e do Grupo
			For nX:=1 To Len(oMsNewGe3:aCols)

				_cFilial := oMsNewGe3:aCols[nX][GdFieldPos("A1_FILIAL",oMsNewGe3:aHeader)]
				cCli  	 := oMsNewGe3:aCols[nX][GdFieldPos("A1_COD",oMsNewGe3:aHeader)]
				cLoja 	 := oMsNewGe3:aCols[nX][GdFieldPos("A1_LOJA",oMsNewGe3:aHeader)]

				If lExistUI3 .and. UI3->( DbSeek(_cFilial+cCli+cLoja) )
					If RecLock("UI3",.F.)
						UI3->UI3_MBLQL	:= Iif(oMsNewGe3:aCols[nX][GdFieldPos("A1_MSBLQL",oMsNewGe3:aHeader)]='1','S','N')
						UI3->UI3_BLQPDV	:= Iif(oMsNewGe3:aCols[nX][GdFieldPos("A1_MSBLQL",oMsNewGe3:aHeader)]='1','S','N')
						UI3->UI3_BLQCR	:= Iif(oMsNewGe3:aCols[nX][GdFieldPos("A1_XBLQLC",oMsNewGe3:aHeader)]='1','S','N')
						//UI3->UI3_EMICHQ	:= oMsNewGe3:aCols[nX][GdFieldPos("UI3EMICHQ",oMsNewGe3:aHeader)]
						UI3->UI3_BLQCHQ := Iif(oMsNewGe3:aCols[nX][GdFieldPos("A1_XEMCHQ",oMsNewGe3:aHeader)]='S','N','S')
						//UI3->UI3_CONDSA	:= oMsNewGe3:aCols[nX][GdFieldPos("UI3CONDSA",oMsNewGe3:aHeader)]
						UI3->UI3_BLQRS	:= Iif(oMsNewGe3:aCols[nX][GdFieldPos("A1_XBLQSQ",oMsNewGe3:aHeader)]='1','S','N')
						//UI3->UI3_BLQRC	:= oMsNewGe3:aCols[nX][GdFieldPos("UI3BLQRC",oMsNewGe3:aHeader)]
						//UI3->UI3_EMITCF	:= oMsNewGe3:aCols[nX][GdFieldPos("UI3EMITCF",oMsNewGe3:aHeader)]
						UI3->UI3_BLQCF  := Iif(oMsNewGe3:aCols[nX][GdFieldPos("A1_XEMICF",oMsNewGe3:aHeader)]=='S','N','S')
						//UI3->UI3_VLSPOS	:= oMsNewGe3:aCols[nX][GdFieldPos("UI3VLSPOS",oMsNewGe3:aHeader)]
						//UI3->UI3_CDVLSP	:= oMsNewGe3:aCols[nX][GdFieldPos("UI3CDVLSP",oMsNewGe3:aHeader)]
						//UI3->UI3_FILBLQ	:= oMsNewGe3:aCols[nX][GdFieldPos("UI3FILBLQ",oMsNewGe3:aHeader)]
						If lMotivo
							UI3->UI3_HISTOR := _cMotivo
						Else
							For nY:=1 To Len(aMotivo)
								If aMotivo[nY][1] .AND. aMotivo[nY][2] == cCli+cLoja
									UI3->UI3_HISTOR := _cMotivo
								EndIf
							Next nY
						EndIf
						UI3->( MsUnlock() )

						//Grava histórico de bloqueio/desbloqueio
						If ChkFile("UA0")
							GravBloqueio(cCli,cLoja,nX)
						EndIf

					EndIf
				EndIf

				If SA1->(DbSetOrder(1), DbSeek(xFilial("SA1")+cCli+cLoja)) .AND. SA1->(FieldPos("A1_XBLQLC" )) > 0
					If RecLock("SA1", .F.)
						SA1->A1_GRPVEN  := oMsNewGe3:aCols[nX][GdFieldPos("A1_GRPVEN",oMsNewGe3:aHeader)]
						SA1->A1_MSBLQL  := oMsNewGe3:aCols[nX][GdFieldPos("A1_MSBLQL",oMsNewGe3:aHeader)]
						SA1->A1_XBLQLC  := oMsNewGe3:aCols[nX][GdFieldPos("A1_XBLQLC",oMsNewGe3:aHeader)]
						SA1->A1_XBLQSQ  := oMsNewGe3:aCols[nX][GdFieldPos("A1_XBLQSQ",oMsNewGe3:aHeader)]
						SA1->A1_XTIPONF := oMsNewGe3:aCols[nX][GdFieldPos("A1_XTIPONF",oMsNewGe3:aHeader)]
						SA1->A1_XODOMET := oMsNewGe3:aCols[nX][GdFieldPos("A1_XODOMET",oMsNewGe3:aHeader)]
						SA1->A1_XMOTOR  := oMsNewGe3:aCols[nX][GdFieldPos("A1_XMOTOR",oMsNewGe3:aHeader)]
						SA1->A1_XFROTA  := oMsNewGe3:aCols[nX][GdFieldPos("A1_XFROTA",oMsNewGe3:aHeader)]
						SA1->A1_XRESTRI := oMsNewGe3:aCols[nX][GdFieldPos("A1_XRESTRI",oMsNewGe3:aHeader)]
						SA1->A1_XCONDSA := oMsNewGe3:aCols[nX][GdFieldPos("A1_XCONDSA",oMsNewGe3:aHeader)]
						SA1->A1_XEMCHQ  := oMsNewGe3:aCols[nX][GdFieldPos("A1_XEMCHQ",oMsNewGe3:aHeader)]
						SA1->A1_XEMICF  := oMsNewGe3:aCols[nX][GdFieldPos("A1_XEMICF",oMsNewGe3:aHeader)]
						SA1->A1_XVLSPOS := oMsNewGe3:aCols[nX][GdFieldPos("A1_XVLSPOS",oMsNewGe3:aHeader)]
						SA1->A1_XCDVLSP := oMsNewGe3:aCols[nX][GdFieldPos("A1_XCDVLSP",oMsNewGe3:aHeader)]
						SA1->A1_XFILBLQ := oMsNewGe3:aCols[nX][GdFieldPos("A1_XFILBLQ",oMsNewGe3:aHeader)]
						SA1->( MsUnlock() )
					EndIf
				EndIf

			Next nX

			If loMSNewGe4 .and. Type("oMsNewGe4") <> "U"
				For nX:=1 To Len(oMsNewGe4:aCols)
					_cFilial	:= oMsNewGe4:aCols[nX][GdFieldPos("ACY_FILIAL",oMsNewGe4:aHeader)]
					cCli    	:= oMsNewGe4:aCols[nX][GdFieldPos("ACY_GRPVEN",oMsNewGe4:aHeader)]
					If ACY->( DbSeek(_cFilial+cCli) )
						If RecLock("ACY",.F.)
							ACY->ACY_XBLPRZ	:= oMsNewGe4:aCols[nX][GdFieldPos("ACY_XBLPRZ",oMsNewGe4:aHeader)]
							ACY->ACY_XBLRSA	:= oMsNewGe4:aCols[nX][GdFieldPos("ACY_XBLRSA",oMsNewGe4:aHeader)]
							ACY->( MsUnlock() )
						EndIf
					EndIf
				Next nX
			EndIf
			MsgInfo("Atualização realizada com sucesso!", "Atencao")

		EndIf

		LoadGrid()

	EndIf

Return

/*/{Protheus.doc} TRETA50A
Usado para posicionar o registro de cada grid na memória para execução de gatilhos, etc...
@type function
@version 1
@author pablo
@since 24/02/2021
/*/
User Function TRETA50A()

	Local cCodCli	:= ""
	Local cLojCli	:= ""
	Local cCodGrp 	:= ""
	Local cCampo 	:= ReadVar()
	Local nX

	cCampo := AllTrim(StrTran(cCampo,"M->",""))

	Do Case
	Case cCampo = "A1_XLC"
		cCodCli := oMsNewGe1:aCols[oMsNewGe1:nAt][GdFieldPos("A1_COD", oMsNewGe1:aHeader)]
		cLojCli := oMsNewGe1:aCols[oMsNewGe1:nAt][GdFieldPos("A1_LOJA", oMsNewGe1:aHeader)]

		oMsNewGe1:aCols[oMsNewGe1:nAt][GdFieldPos("A1_XSLDLC", oMsNewGe1:aHeader)] := IF(FindFunction("U_TRETE032") .AND. !INCLUI, M->A1_XLC-U_TRETE032(1,{{cCodCli,cLojCli,''}})[01][01], M->A1_XLC)

	Case cCampo = "A1_XLIMSQ"
		cCodCli := oMsNewGe1:aCols[oMsNewGe1:nAt][GdFieldPos("A1_COD", oMsNewGe1:aHeader)]
		cLojCli := oMsNewGe1:aCols[oMsNewGe1:nAt][GdFieldPos("A1_LOJA", oMsNewGe1:aHeader)]

		oMsNewGe1:aCols[oMsNewGe1:nAt][GdFieldPos("A1_XSLDSQ", oMsNewGe1:aHeader)] := IF(FindFunction("U_TRETE032") .AND. !INCLUI, M->A1_XLIMSQ-U_TRETE032(2,{{cCodCli,cLojCli,''}})[01][01], M->A1_XLIMSQ)

	Case cCampo = "ACY_XLC"
		cCodGrp := oMSNewGe2:aCols[oMSNewGe2:nAt][GdFieldPos("ACY_GRPVEN", oMSNewGe2:aHeader)]

		oMSNewGe2:aCols[oMSNewGe2:nAt][GdFieldPos("ACY_XSLDLC", oMSNewGe2:aHeader)] := IF(FindFunction("U_TRETE032") .AND. !INCLUI, M->ACY_XLC-U_TRETE032(1,{{'','',cCodGrp}})[01][02], M->ACY_XLC)

	Case cCampo = "ACY_XLIMSQ"
		cCodGrp := oMSNewGe2:aCols[oMSNewGe2:nAt][GdFieldPos("ACY_GRPVEN", oMSNewGe2:aHeader)]

		oMSNewGe2:aCols[oMSNewGe2:nAt][GdFieldPos("ACY_XSLDSQ", oMSNewGe2:aHeader)] := IF(FindFunction("U_TRETE032") .AND. !INCLUI, M->ACY_XLIMSQ-U_TRETE032(2,{{'','',cCodGrp}})[01][02], M->ACY_XLIMSQ)

		// Motivos dos Bloqueios Clientes
	Case AllTrim(cCampo) $ "A1_MSBLQL/A1_XBLQLC/A1_XBLQSQ" //A1_XEMCHQ/A1_XEMICF
		cCodCli := oMsNewGe3:aCols[oMsNewGe3:nAt][GdFieldPos("A1_COD", oMsNewGe3:aHeader)]
		cLojCli := oMsNewGe3:aCols[oMsNewGe3:nAt][GdFieldPos("A1_LOJA", oMsNewGe3:aHeader)]

		For nX:=1 To Len(aMotivo)
			If aMotivo[nX][2] == cCodCli+cLojCli
				aMotivo[nX][1] := .T.
			EndIf
		Next nX

		// Motivos dos Bloqueios Grupo
	Case cCampo $ "ACY_XBLPRZ/ACY_XBLRSA"
		lMotivo := .T.

		//OtherWise

	End Case

Return .T.

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa   ³   C()   ³ Autores ³ Norbert/Ernani/Mansano ³ Data ³10/05/2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao  ³ Funcao responsavel por manter o Layout independente da       ³±±
±±³           ³ resolucao horizontal do Monitor do Usuario.                  ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
Static Function C(nTam)

Local nHRes	:=	oMainWnd:nClientWidth	// Resolucao horizontal do monitor

	If nHRes == 640	// Resolucao 640x480 (soh o Ocean e o Classic aceitam 640)
		nTam *= 0.8
	ElseIf (nHRes == 798).Or.(nHRes == 800)	// Resolucao 800x600
		nTam *= 1
	Else	// Resolucao 1024x768 e acima
		nTam *= 1.28
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Tratamento para tema "Flat"³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If "MP8" $ oApp:cVersion
		If (Alltrim(GetTheme()) == "FLAT") .Or. SetMdiChild()
			nTam *= 0.90
		EndIf
	EndIf

Return Int(nTam)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  Motivo   ºAutor  Raphael Martins      º Data ³  06/29/15     º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Tela de digitação de motivo de bloqueio ou desbloqueio de  º±±
±±º          ³ clientes, chamada a partir das validacoes do campos de blq º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Marajo                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function Motivo()

	Local oDlgMot
	Local oMemo
	Local oGroup
	Local cTexto := Space(60)
	Local lRet   := .T.
	Local nP12   := 0

	If '12' $ cVersao //para a versao do Protheus 12
		nP12 := 27
	EndIf

	DEFINE MSDIALOG oDlgMot TITLE "Digite o Motivo do Bloqueio ou Desbloqueio" From 8,0 To 200+nP12,350 PIXEL

	@ 002, 002 GROUP oGroup TO 085+nP12, 175 PROMPT " Motivo de Bloqueio/Desbloqueio " OF oDlgMot COLOR 0, 16777215 PIXEL

	oMemo := TMultiget():Create(oDlgMot,{|u|if(Pcount()>0, cTexto:=u,cTexto)},010+nP12,005,165,068,,.T.,,,,.T.)
	oMemo:EnableVScroll(.T.)

	ACTIVATE MSDIALOG oDlgMot CENTERED ON INIT EnchoiceBar( oDlgMot, { ||  lRet := ValidaMotivo(cTexto,oDlgMot)}, {|| lRet := .F.,oDlgMot:End()})

Return(lRet)

//------------------------------------------------
// Valida Motivo de Bloqueio ou Desbloqueio
//------------------------------------------------
Static Function ValidaMotivo(cMotivo,oObj)
//------------------------------------------------
	Local lRet     := .T.
	Local cCodUser := RetCodUsr()

	If Empty(cMotivo)
		MsgAlert("O Preenchimento do Motivo é Obrigatório!","Atenção!")
		lRet := .F.
	Else
		_cMotivo := DtoC(DDataBase) + CRLF + "Usuário:" + cCodUser + " - " + UsrFullName(cCodUser) + CRLF + ALLTRIM(cMotivo)
		oObj:End()
	EndIf

Return(lRet)

//------------------------------------------------
Static Function CruzaDados(nOpc,oSay)
//------------------------------------------------
	Local cCodCli 	:= ""
	Local cLojCli	:= ""

	If nOpc == 1
		cCodCli := oMsNewGe1:aCols[oMsNewGe1:nAt][GdFieldPos("A1_COD", oMsNewGe1:aHeader)]
		cLojCli := oMsNewGe1:aCols[oMsNewGe1:nAt][GdFieldPos("A1_LOJA", oMsNewGe1:aHeader)]
	ElseIf nOpc == 2
		cCodCli := oMsNewGe3:aCols[oMsNewGe3:nAt][GdFieldPos("A1_COD", oMsNewGe3:aHeader)]
		cLojCli := oMsNewGe3:aCols[oMsNewGe3:nAt][GdFieldPos("A1_LOJA", oMsNewGe3:aHeader)]
	Else
		cCodCli := oMsNewGe5:aCols[oMsNewGe5:nAt][GdFieldPos("A1_COD", oMsNewGe5:aHeader)]
		cLojCli := oMsNewGe5:aCols[oMsNewGe5:nAt][GdFieldPos("A1_LOJA", oMsNewGe5:aHeader)]
	EndIf

	If !Empty(AllTrim(cCodCli)) .AND. !Empty(AllTrim(cLojCli))
		If FindFunction('U_ULOJA166') .and. U_ULOJA166(cCodCli,cLojCli) //Cruzamento de Dados de Clientes.
			Eval(_MSG,"Atualizando Informações...")
			LoadGrid()
		EndIf
	Else
		MsgAlert("Posicione no cliente que deseja executar o processamento!","Atencao")
	EndIf

Return

//------------------------------------------------
Static Function CallSerasa(nOpc)
//------------------------------------------------
	Local cCodCli 	:= ""
	Local cLojCli	:= ""

	If nOpc == 1
		cCodCli := oMsNewGe1:aCols[oMsNewGe1:nAt][GdFieldPos("A1_COD", oMsNewGe1:aHeader)]
		cLojCli := oMsNewGe1:aCols[oMsNewGe1:nAt][GdFieldPos("A1_LOJA", oMsNewGe1:aHeader)]
	ElseIf nOpc == 2
		cCodCli := oMsNewGe3:aCols[oMsNewGe3:nAt][GdFieldPos("A1_COD", oMsNewGe3:aHeader)]
		cLojCli := oMsNewGe3:aCols[oMsNewGe3:nAt][GdFieldPos("A1_LOJA", oMsNewGe3:aHeader)]
	ElseIf nOpc == 3
		cCodCli := oMsNewGe5:aCols[oMsNewGe5:nAt][GdFieldPos("A1_COD", oMsNewGe5:aHeader)]
		cLojCli := oMsNewGe5:aCols[oMsNewGe5:nAt][GdFieldPos("A1_LOJA", oMsNewGe5:aHeader)]
	Else
		cCodCli := oMsNewGe5:aCols[oMsNewGe5:nAt][GdFieldPos("A1_COD", oMsNewGe5:aHeader)]
		cLojCli := oMsNewGe5:aCols[oMsNewGe5:nAt][GdFieldPos("A1_LOJA", oMsNewGe5:aHeader)]
	EndIf

	DbSelectArea("SA1")
	If FindFunction("U_UFIN010A") .and. SA1->( DbSetOrder(1), DbSeek(xFilial("SA1")+cCodCli+cLojCli) ) //consulta serasa
		FWExecView('Consulta Serasa','UFINC010', 4,, {|| .T. /*fecha janela no ok*/ })
		LoadGrid()
	EndIf

Return

//------------------------------------------------
Static Function GravBloqueio(cCliente,cLoja,nX)
//------------------------------------------------
	Local aArea      := GetArea()
	Local aAreaUA0   := UA0->( GetArea() )
	Local aAreaUI3   := UI3->( GetArea() )
	Local nSequencia := 0
	Local cCondicao  := ""
	Local bCondicao
	Default cCliente   := ""
	Default cLoja      := ""
	Default nX		   := 1

/*
Valida se houve alteracao nos campos de bloqueio º±±
*/
	UA0->(DbClearFilter())

	cCondicao := " UA0->UA0_FILIAL == '" + xFilial("UA0") + "'  "
	cCondicao += " .AND. UA0->UA0_CLIENT == '"+cCliente+"'   "
	cCondicao += " .AND. UA0->UA0_LOJA == '"+cLoja+"'    "

	UA0->( DbSetOrder(1) )
	UA0->(DbClearFilter())

// faço um filtro na UA0
	bCondicao := "{|| " + cCondicao + " }"
	UA0->(DbSetFilter(&bCondicao,cCondicao))

// posiciono no ultimo registro
	UA0->( dbGoBottom() )

	nSequencia := UA0->UA0_SEQ + 1

	If UA0->( !EOF() )
		//Cliente com Bloqueio, Historico desbloqueado
		If 	( oMsNewGe3:aCols[nX][GdFieldPos("A1_MSBLQL",oMsNewGe3:aHeader)] 	== '1' .And. UA0->UA0_BLPADR <> 'S')	.Or. ;
				( oMsNewGe3:aCols[nX][GdFieldPos("A1_MSBLQL",oMsNewGe3:aHeader)] 	== '1' .And. UA0->UA0_BLQPDV <> 'S')	.Or. ;
				( oMsNewGe3:aCols[nX][GdFieldPos("A1_XEMICF",oMsNewGe3:aHeader)] 	== 'S' .And. UA0->UA0_CARTFR <> 'N')	.Or. ;
				( oMsNewGe3:aCols[nX][GdFieldPos("A1_XBLQSQ",oMsNewGe3:aHeader)] 	== '1' .And. UA0->UA0_BLRESA <> 'S')	.Or. ;
				( oMsNewGe3:aCols[nX][GdFieldPos("A1_XBLQLC",oMsNewGe3:aHeader)] 	== '1' .And. UA0->UA0_BLQPRZ <> 'S' )	.Or. ;
				( oMsNewGe3:aCols[nX][GdFieldPos("A1_XEMCHQ",oMsNewGe3:aHeader)] 	== 'S' .And. UA0->UA0_BLQCHQ <> 'N')

			GravaHist(1,nSequencia,cCliente,cLoja,nX) //Grava Historico e altera Status do cliente

		ElseIf 	( oMsNewGe3:aCols[nX][GdFieldPos("A1_MSBLQL",oMsNewGe3:aHeader)] 	<> '1' .And. UA0->UA0_BLPADR == 'S')	.Or. ;
				( oMsNewGe3:aCols[nX][GdFieldPos("A1_MSBLQL",oMsNewGe3:aHeader)] 	<> '1' .And. UA0->UA0_BLQPDV == 'S')	.Or. ;
				( oMsNewGe3:aCols[nX][GdFieldPos("A1_XEMICF",oMsNewGe3:aHeader)] 	<> 'S' .And. UA0->UA0_CARTFR <> 'S')	.Or. ;
				( oMsNewGe3:aCols[nX][GdFieldPos("A1_XBLQSQ",oMsNewGe3:aHeader)] 	<> '1' .And. UA0->UA0_BLRESA == 'S')	.Or. ;
				( oMsNewGe3:aCols[nX][GdFieldPos("A1_XBLQLC",oMsNewGe3:aHeader)] 	<> '1' .And. UA0->UA0_BLQPRZ == 'S' )	.Or. ;
				( oMsNewGe3:aCols[nX][GdFieldPos("A1_XEMCHQ",oMsNewGe3:aHeader)] 	<> 'S' .And. UA0->UA0_BLQCHQ <> 'S')

			GravaHist(2,nSequencia,cCliente,cLoja,nX) //Grava Historico e altera Status do cliente
		EndIf

/* CASO NAO POSSUA HISTORICO VALIDA SE HOUVE ALTERACAO DE CAMPOS DE BLOQUEIO, CASO HOUVER GERA HISTORICO NA UA0*/
	ElseIf !Empty(_cMotivo)

		If  oMsNewGe3:aCols[nX][GdFieldPos("A1_MSBLQL",oMsNewGe3:aHeader)] 	== '1'	.Or. ;
				oMsNewGe3:aCols[nX][GdFieldPos("A1_XEMICF",oMsNewGe3:aHeader)] 	<> 'S'	.Or. ;
				oMsNewGe3:aCols[nX][GdFieldPos("A1_XBLQSQ",oMsNewGe3:aHeader)] 	== '1'	.Or. ;
				oMsNewGe3:aCols[nX][GdFieldPos("A1_XBLQLC",oMsNewGe3:aHeader)] 	== '1'	.Or. ;
				oMsNewGe3:aCols[nX][GdFieldPos("A1_XEMCHQ",oMsNewGe3:aHeader)] 	<> 'S'

			GravaHist(1,nSequencia,cCliente,cLoja,nX) //Grava Historico e altera Status do cliente
		Else
			GravaHist(2,nSequencia,cCliente,cLoja,nX) //Grava Historico e altera Status do cliente
		EndIf

	EndIf

	UA0->(DbClearFilter())
	UA0->( DbGotop() )

	RestArea(aAreaUA0)
	RestArea(aAreaUI3)
	RestArea(aArea)

Return()

//------------------------------------------------
Static Function GravaHist(nOpcA,nSequencia,cCliente,cLoja,nX)
//------------------------------------------------
	Local _cUserCod    := RetCodUsr()

	Default nOpcA      := 1
	Default nSequencia := 1
	Default nX		:= 1

	If !Empty(cCliente) .And. !Empty(cLoja) .And.  !Empty(_cMotivo)

		RecLock("UA0",.T.)

		UA0->UA0_FILIAL := xFilial("UA0")
		UA0->UA0_CLIENT := cCliente
		UA0->UA0_LOJA   := cLoja
		UA0->UA0_DATA   := DDATABASE
		UA0->UA0_OPER   := If(nOpcA == 1,'B','D')
		UA0->UA0_USER  	:= If(!Empty(_cUserCod),_cUserCod,'000000')
		UA0->UA0_SEQ    := nSequencia
		UA0->UA0_MOTIVO := _cMotivo
		UA0->UA0_BLPADR := Iif(oMsNewGe3:aCols[nX][GdFieldPos("A1_MSBLQL",oMsNewGe3:aHeader)]=='1','S','N') //Bloqueio Padrao
		UA0->UA0_BLQPDV := Iif(oMsNewGe3:aCols[nX][GdFieldPos("A1_MSBLQL",oMsNewGe3:aHeader)]=='1','S','N') //Bloqueio PDV
		UA0->UA0_BLQCHQ := Iif(oMsNewGe3:aCols[nX][GdFieldPos("A1_XEMCHQ",oMsNewGe3:aHeader)]=='S','N','S') //Bloq. Emissao Cheque
		UA0->UA0_CARTFR := Iif(oMsNewGe3:aCols[nX][GdFieldPos("A1_XEMICF",oMsNewGe3:aHeader)]=='S','N','S') //Bloq. Emtente Liberac. CF
		//UA0->UA0_BLRECO := oMsNewGe3:aCols[nX][GdFieldPos("UI3BLQRC",oMsNewGe3:aHeader)]
		UA0->UA0_BLRESA := Iif(oMsNewGe3:aCols[nX][GdFieldPos("A1_XBLQSQ",oMsNewGe3:aHeader)]=='1','S','N') //Bloqueio Req. Saque
		UA0->UA0_BLQPRZ := Iif(oMsNewGe3:aCols[nX][GdFieldPos("A1_XBLQLC",oMsNewGe3:aHeader)]=='1','S','N') //Bloq. Titulo a Receber

		UA0->( MsUnlock() )
	EndIf

Return()
