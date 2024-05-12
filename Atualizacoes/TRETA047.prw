#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'

/*/{Protheus.doc} TRETA047
Rotina de Acompanhamento de Preços - Marajo

@param xParam Parameter Description
@return xRet Return Description
@author Danilo
@since 21/01/2020
/*/
User function TRETA047(_lCadCli)

	Local oDlg 		    := NIL
	Local aCoors 	    := FWGetDialogSize(oMainWnd)  
	Local aSeekPrd 		:= {}
	Local lFilterOk 	:= .F.
	Default _lCadCli		:= .F. 
	Private aParamEnc 	:= {}
	Private aCampos 	:= {"U25_FILIAL","U25_PRODUT", "B1_DESC", "U25_PRCVEN", "D1_VUNIT", "U25_CLIENT", "U25_LOJA", "A1_NOME", "U25_GRPCLI", "ACY_DESCRI", "U25_FORPAG", "U25_CONDPG", "U44_DESCRI", "U25_ADMFIN", "U25_DATA", "U25_HORA", "U25_USER", "A1_XCOMERC", "U25_DTINIC", "U25_HRINIC", "U25_DTFIM","U25_HRFIM"}
	Private oTable as object
	Private cAlias as char
	Private cTableName as char
	Private lCadCli := _lCadCli
	
	//Cria tabela temporaria
	CriaTempAlias()

	//faz primeiro filtro
	FWMsgRun(,{|oSay| lFilterOk := DoFilter() },'Aguarde','Buscando registros...')
	
	if !lFilterOk
		Return
	endif

	DEFINE MSDIALOG oDlg FROM aCoors[1], aCoors[2] To aCoors[3], aCoors[4] PIXEL TITLE "Acompanhamento de Preços" OF GetWndDefault() STYLE nOr(WS_VISIBLE, WS_POPUP)

	// Define o Browse
	oBrowse := FWBrowse():New(oDlg)
	oBrowse:SetAlias( cAlias )
	oBrowse:SetDescription("Acompanhamento de Preços Negociados")
	oBrowse:SetDataTable(.T.)
	//oBrowse:DisableReport()
	//oBrowse:DisableSeek()
	oBrowse:DisableSaveConfig()
	oBrowse:DisableConfig()

	// Botão pesquisar
	Aadd(aSeekPrd,{"Cod. Cliente"	, {{"","C",TamSX3("U25_FILIAL")[1]+TamSX3("U25_CLIENT")[1]+TamSX3("U25_LOJA")[1], 0, "Cod. Cliente", PesqPict("U25","U25_CLIENT")}}, 	1, .T.})
	Aadd(aSeekPrd,{"Nome Cliente"	, {{"","C",TamSX3("U25_FILIAL")[1]+TamSX3("A1_NOME")[1], 0,"Nome Cliente", PesqPict("SA1","A1_NOME")}}, 	2, .T.})
	Aadd(aSeekPrd,{"Grupo Cliente"	, {{"","C",TamSX3("U25_FILIAL")[1]+TamSX3("U25_GRPCLI")[1], 0,"Grupo Cliente", PesqPict("U25","U25_GRPCLI")}}, 	3, .T.})
	Aadd(aSeekPrd,{"Nome Grupo"		, {{"","C",TamSX3("U25_FILIAL")[1]+TamSX3("ACY_DESCRI")[1], 0,"Nome Grupo", PesqPict("ACY","ACY_DESCRI")}}, 	4, .T.})
	oBrowse:SetSeek(, aSeekPrd)
	
	// Adiciona legenda no Browse
	oBrowse:AddLegend('U25_PRCVEN < D1_VUNIT',"RED","Preço Venda Abaixo Ultima Compra")
	oBrowse:AddLegend('U25_PRCVEN >= D1_VUNIT',"GREEN","Preço Venda Acima Ultima Compra")
	
	AddColunasBrw()

	// Ativação do Browse
	oBrowse:Activate()

	// Botões
	@ 022.5, 065 BUTTON oBotao1 PROMPT "Atualizar Filtro" SIZE 060, 015 OF oDlg PIXEL ACTION AtuGrid(oBrowse)
	@ 022.5, 127 BUTTON oBotao1 PROMPT "Legenda" SIZE 040, 015 OF oDlg PIXEL ACTION BtnLegenda()

	TBtnBmp2():New( 005, (aCoors[4])-020, 20, 30,'FWSKIN_DELETE_ICO',,,,{|| oDlg:End() },oDlg,,,.T. )

	oBrowse:SetFocus()

	ACTIVATE MSDIALOG oDlg CENTERED

	oBrowse:DeActivate()

	//-------------------------------------------------------------------
    //Fecho e apago a tabela temporária
    //Por mais que a tabela temporária seja excluída de forma automática,
    //é sempre uma boa prática fechar e excluir a mesma
    //-------------------------------------------------------------------
    oTable:Delete()

Return

Static Function CriaTempAlias()

	Local nI
	Local aFields as array
	Local cTipo as char
	Local aTamSX3 as array

	//--------------------------------------------------------------------
    //O primeiro parâmetro de alias, possui valor default
    //O segundo parâmetro de campos, pode ser atribuido após o construtor
    //--------------------------------------------------------------------
    oTable := FWTemporaryTable():New( /*cAlias*/, /*aFields*/)

    //----------------------------------------------------
    //O array de campos segue o mesmo padrão do DBCreate:
    //1 - C - Nome do campo
    //2 - C - Tipo do campo
    //3 - N - Tamanho do campo
    //4 - N - Decimal do campo
    //----------------------------------------------------
    aFields := {}

	For nI := 1 to len(aCampos)

		cTipo := GetSx3Cache( aCampos[nI] , "X3_TIPO" )
		aTamSX3 := TamSX3(aCampos[nI])

		aAdd(aFields, {aCampos[nI], cTipo, aTamSX3[1], aTamSX3[2]})
	
	next nI

    oTable:SetFields(aFields)

    //---------------------
    //Criação dos índices
    //---------------------
    oTable:AddIndex("01", {"U25_FILIAL","U25_CLIENT","U25_LOJA","U25_GRPCLI","U25_FORPAG","U25_CONDPG","U25_ADMFIN"} )
    oTable:AddIndex("02", {"U25_FILIAL","A1_NOME","U25_GRPCLI","U25_FORPAG","U25_CONDPG","U25_ADMFIN"} )
    oTable:AddIndex("03", {"U25_FILIAL","U25_GRPCLI","U25_CLIENT","U25_LOJA","U25_FORPAG","U25_CONDPG","U25_ADMFIN"} )
    oTable:AddIndex("04", {"U25_FILIAL","ACY_DESCRI","U25_CLIENT","U25_LOJA","U25_FORPAG","U25_CONDPG","U25_ADMFIN"} )

    //---------------------------------------------------------------
    //Pronto, agora temos a tabela criado no espaço temporário do DB
    //---------------------------------------------------------------
    oTable:Create()

    //------------------------------------
    //Pego o alias da tabela temporária
    //------------------------------------
    cAlias := oTable:GetAlias()

    //--------------------------------------------------------
    //Pego o nome real da tabela temporária no banco de dados
    //--------------------------------------------------------
    cTableName := oTable:GetRealName()

Return

//definição dos campos do browse
Static Function AddColunasBrw()

	Local nI
	Local aColumn
	Local nAlign := 1
	Local cTipo := ""
	Local bData
	Local cTitle := ""

	For nI := 1 to len(aCampos)

		nAlign := 1
		cTipo := GetSx3Cache( aCampos[nI] , "X3_TIPO" )
		cTitle := Alltrim(RetTitle(aCampos[nI]))

		if aCampos[nI] == "D1_VUNIT"
			cTitle := "Prc. Ultima Compra"
		endif
		
		if aCampos[nI] == "U25_USER"
			bData := &("{|| USRRETNAME(U25_USER)  }")
		elseif aCampos[nI] == "A1_XCOMERC"
			bData := &("{|| iif(empty(U25_GRPCLI),A1_XCOMERC, Posicione('SA1',6,xFilial('SA1')+U25_GRPCLI,'A1_XCOMERC') ) }")
		else
			bData := &("{|| " + aCampos[nI] +" }")
			if cTipo == "N"
				nAlign := 2
			endif
		endif
		

		/* Array da coluna
		[n][01] Título da coluna
		[n][02] Code-Block de carga dos dados
		[n][03] Tipo de dados
		[n][04] Máscara
		[n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
		[n][06] Tamanho
		[n][07] Decimal
		[n][08] Indica se permite a edição
		[n][09] Code-Block de validação da coluna após a edição
		[n][10] Indica se exibe imagem
		[n][11] Code-Block de execução do duplo clique
		[n][12] Variável a ser utilizada na edição (ReadVar)
		[n][13] Code-Block de execução do clique no header
		[n][14] Indica se a coluna está deletada
		[n][15] Indica se a coluna será exibida nos detalhes do Browse
		[n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
		*/
		aColumn := {cTitle,; 
					bData, ;
					cTipo,;
					GetSx3Cache(aCampos[nI],"X3_PICTURE"),; 
					nAlign, ;
					TamSX3(aCampos[nI])[1], ;
					TamSX3(aCampos[nI])[2], ;
					.F.,{||.T.},.F.,{||.T.},NIL,{||.T.},.F.,.F.,{}}

		oBrowse:SetColumns({aColumn})

	next nI

Return

//Atualiza dados do grid com novos filtros
Static Function AtuGrid(oBrowse)
	
	Local lFilterOk := .F.

	FWMsgRun(,{|oSay| lFilterOk := DoFilter() },'Aguarde','Buscando registros...')

	if lFilterOk
		oBrowse:SetFocus()
		oBrowse:GoTop(.T.)
		//oBrowse:Refresh(.T.)
		//oBrowse:UpdateBrowse(.T.)
	endif

Return

//Faz Qry do filtro
Static Function DoFilter()

	Local lRet := .T.
	Local lNgDesc := SuperGetMV("MV_XNGDESC",,.T.) //Ativa negociação pelo valor de desconto: U25_DESPBA
	Local lTipoPreco := GetMv("MV_LJCNVDA")
	Local cTabPrc := GetMv("MV_TABPAD")
	Local cQry := ""
	Local aPergs := {}
	Local cOperads := {"",">","<",">=","<=","="}
	Local nI
	Local cFields := ""
	Local cSGBD 	 	:= Upper(AllTrim(TcGetDB()))	// Guarda Gerenciador de banco de dados

	if empty(aParamEnc)
		aadd(aParamEnc, Space(TamSX3("U25_PRODUT")[1]))
		aadd(aParamEnc, Space(TamSX3("U25_FORPAG")[1]))
		aadd(aParamEnc, Space(TamSX3("U25_CONDPG")[1]))
		if lCadCli
			aadd(aParamEnc, SA1->A1_COD)
			aadd(aParamEnc, SA1->A1_LOJA)
			aadd(aParamEnc, SA1->A1_GRPVEN)
		else
			aadd(aParamEnc, Space(TamSX3("U25_CLIENT")[1]))
			aadd(aParamEnc, Space(TamSX3("U25_LOJA")[1]))
			aadd(aParamEnc, Space(TamSX3("U25_GRPCLI")[1]))
		endif
		aadd(aParamEnc, Space(TamSX3("U25_ADMFIN")[1]))
		aadd(aParamEnc, .F.)
		aadd(aParamEnc, "1")
		aadd(aParamEnc, 0)
		aadd(aParamEnc, Space(TamSX3("U25_FILIAL")[1]))
	endif

	aAdd(aPergs ,{1,"Produto",aParamEnc[1],PesqPict("U25","U25_PRODUT"),'.T.',"SB1",'.T.',80,!lCadCli})
	aAdd(aPergs ,{1,"Forma Pgto",aParamEnc[2],PesqPict("U25","U25_FORPAG"),'.T.',"24",'.T.',40,.F.})
	aAdd(aPergs ,{1,"Condição Pgto",aParamEnc[3],PesqPict("U25","U25_CONDPG"),'.T.',"SE4",'.T.',40,.F.})
	aAdd(aPergs ,{1,"Cliente",aParamEnc[4],PesqPict("U25","U25_CLIENT"),'.T.',"SA1",'!lCadCli',80,.F.})
	aAdd(aPergs ,{1,"Loja",aParamEnc[5],PesqPict("U25","U25_LOJA"),'.T.',"",'!lCadCli',40,.F.})
	aAdd(aPergs ,{1,"Grupo Cliente",aParamEnc[6],PesqPict("U25","U25_GRPCLI"),'.T.',"ACY",'!lCadCli',80,.F.})
	aAdd(aPergs ,{1,"Adm. Financeira",aParamEnc[7],PesqPict("U25","U25_ADMFIN"),'.T.',"SAE",'.T.',40,.F.})
	aAdd(aPergs ,{4,"Considerar Preço ?",aParamEnc[8],"Abaixo Ultima NF Entrada",90,"",.F.})
	aAdd(aPergs ,{2,"Preço Negociado",aParamEnc[9],{"1=Ignora Filtro","2=Maior que","3=Menor que","4=Maior ou Igual a","5=Menor ou Igual a","6=Igual a"},80,"",.F.})
	aAdd(aPergs ,{1,"Valor",aParamEnc[10],PesqPict("U25","U25_PRCVEN"),'.T.',"",'.T.',50,.F.})
	aAdd(aPergs ,{1,"Filial",aParamEnc[11],"@!",'.T.',"SM0",'.T.',50,.F.})

	if !ParamBox(aPergs ,"Filtro de Preços -",@aParamEnc,,,,,,,.F.,.F.)
		lRet := .F.
		Return lRet
	endif

	//-------------------------------------------------------------------------
    //Limpando tabela de dados via DELETE, vamos usar o nome real da tabela para isso
    //-------------------------------------------------------------------------
    cQry := ""
    cQry += "DELETE FROM " + cTableName + " "

    if TCSqlExec(cQry) < 0
        Alert(TCSqlError())
		lRet := .F.
		Return lRet
    endif

	//Pega todos os campos para efetuar a cópia dos dados
	for nI := 1 to Len(aCampos)
		cFields += aCampos[nI] + ","//Nome do campo
	next
	cFields := Left(cFields, Len(cFields) -1) //Remover a ultima vírgula

	//-------------------------------------------------------------------------
    //Inserção de dados via INSERT, vamos usar o nome real da tabela para isso
    //-------------------------------------------------------------------------
    cQry := ""
    cQry += "INSERT INTO " + cTableName + " ("+cFields+")  "//VALUES
    If !("ORACLE" $ cSGBD)
    	cQry += "("
	endif

	cQry += " SELECT TMP.* FROM "

	cQry += " (SELECT U25_FILIAL, U25_PRODUT, B1_DESC, "

	if lNgDesc
		If "ORACLE" $ cSGBD //Oracle 
            cQry += " (ISNULL((SELECT U0C_PRCBAS "
        else
            cQry += " (ISNULL((SELECT TOP 1 U0C_PRCBAS "
        endif
		cQry += " FROM "+RetSqlName("U0C")+" U0C "
		cQry += " WHERE U0C.D_E_L_E_T_ = ' ' "
		cQry += " AND U0C_FILIAL = U25_FILIAL "
		cQry += " AND U0C_PRODUT = U25_PRODUT "
		cQry += " AND (U0C_FORPAG = ' ' OR U0C_FORPAG = U25_FORPAG) "
		cQry += " AND (U0C_CONDPG = ' ' OR U0C_CONDPG = U25_CONDPG) "
		cQry += " AND (U0C_ADMFIN = ' ' OR U0C_ADMFIN = U25_ADMFIN) "
		If "ORACLE" $ cSGBD //Oracle 
		    cQry += " AND ROWNUM <= 1"
        endif
		cQry += " ORDER BY U0C_FORPAG DESC, U0C_CONDPG DESC, U0C_ADMFIN DESC) "
		cQry += " ,ISNULL(( "
		if lTipoPreco
			If "ORACLE" $ cSGBD //Oracle 
				cQry += " SELECT DA1_PRCVEN "
			else
				cQry += " SELECT TOP 1 DA1_PRCVEN "
			endif
			cQry += " FROM "+RetSqlName("DA1")+" DA1 "
			cQry += " WHERE DA1.D_E_L_E_T_ = ' ' "
			cQry += " AND DA1_FILIAL = '"+xFilial("DA1")+"' "
			cQry += " AND DA1_CODTAB = '"+cTabPrc+"' "
			cQry += " AND DA1_CODPRO = U25_PRODUT "
			cQry += " AND DA1_DATVIG <= '"+DTOS(dDataBase)+"' "
			If "ORACLE" $ cSGBD //Oracle 
				cQry += " AND ROWNUM <= 1"
			endif
			cQry += " ORDER BY DA1_DATVIG DESC "
		else
			If "ORACLE" $ cSGBD //Oracle 
				cQry += " SELECT B0_PRV1 "
			else
				cQry += " SELECT TOP 1 B0_PRV1 "
			endif
			cQry += " FROM "+RetSqlName("SB0")+" SB0 "
			cQry += " WHERE SB0.D_E_L_E_T_ = ' ' "
			cQry += " AND B0_FILIAL = U25_FILIAL "
			cQry += " AND B0_COD = U25_PRODUT "
			If "ORACLE" $ cSGBD //Oracle 
				cQry += " AND ROWNUM <= 1"
			endif
		endif
		cQry += " ),0)) - U25_DESPBA) AS U25_PRCVEN, "
	else
		cQry += " U25_PRCVEN, "
	endif

	//ULTIMA COMPRA
	If "ORACLE" $ cSGBD //Oracle 
		cQry += " ISNULL((SELECT D1_VUNIT "
	else
		cQry += " ISNULL((SELECT TOP 1 D1_VUNIT "
	endif
	cQry += " FROM "+RetSqlName("SD1")+" SD1"
	cQry += " WHERE D_E_L_E_T_<> '*' "
	cQry += " AND D1_FILIAL = U25_FILIAL "
	cQry += " AND D1_COD = U25_PRODUT " 
	cQry += " AND D1_TIPO = 'N'" //notas entrada normal
	If "ORACLE" $ cSGBD //Oracle 
		cQry += " AND ROWNUM <= 1"
	endif
	cQry += " ORDER BY D1_EMISSAO DESC, D1_NUMSEQ DESC), 0) AS D1_VUNIT, "

	//DEMAIS DADOS 
	cQry += " U25_CLIENT, U25_LOJA, ISNULL(A1_NOME,'') A1_NOME, U25_GRPCLI, ISNULL(ACY_DESCRI,'') ACY_DESCRI, "
	cQry += " U25_FORPAG, U25_CONDPG, ISNULL(U44_DESCRI,'') U44_DESCRI, U25_ADMFIN, "
	cQry += " U25_DATA, U25_HORA, U25_USER, ISNULL(A1_XCOMERC,'') A1_XCOMERC, "
	cQry += " U25_DTINIC, U25_HRINIC, U25_DTFIM, U25_HRFIM "

	cQry += " FROM "+RetSqlName("U25")+" U25 "

	//PRODUTOS
	cQry += " INNER JOIN "+RetSqlName("SB1")+" SB1 ON SB1.D_E_L_E_T_ = ' ' "
	if empty(xFilial("SB1")) //se for compartilhada total
		cQry += " AND B1_FILIAL = '"+xFilial("SB1")+"'"
	elseif Len(Alltrim(xFilial("SB1"))) == Len(Alltrim(xFilial("U25"))) //se SB1 é exclusiva
		cQry += " AND B1_FILIAL = U25_FILIAL "
	else //compartilhada parcialmente
		cQry += " AND SUBSTRING(B1_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("SB1"))))+") = SUBSTRING(U25_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("SB1"))))+")  "
	endif
	cQry += " AND B1_COD = U25_PRODUT  "

	//CLIENTES
	cQry += " LEFT JOIN "+RetSqlName("SA1")+" SA1 ON SA1.D_E_L_E_T_ = ' ' "
	if empty(xFilial("SA1")) //se for compartilhada total
		cQry += " AND A1_FILIAL = '"+xFilial("SA1")+"'"
	elseif Len(Alltrim(xFilial("SA1"))) == Len(Alltrim(xFilial("U25"))) //se SA1 é exclusiva
		cQry += " AND A1_FILIAL = U25_FILIAL "
	else //compartilhada parcialmente
		cQry += " AND SUBSTRING(A1_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("SA1"))))+") = SUBSTRING(U25_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("SA1"))))+")  "
	endif
	cQry += " AND A1_COD = U25_CLIENT AND A1_LOJA = U25_LOJA "

	//GRUPO CLIENTES
	cQry += " LEFT JOIN "+RetSqlName("ACY")+" ACY ON ACY.D_E_L_E_T_ = ' ' "
	if empty(xFilial("ACY")) //se for compartilhada total
		cQry += " AND ACY_FILIAL = '"+xFilial("ACY")+"'"
	elseif Len(Alltrim(xFilial("ACY"))) == Len(Alltrim(xFilial("U25"))) //se ACY é exclusiva
		cQry += " AND ACY_FILIAL = U25_FILIAL "
	else //compartilhada parcialmente
		cQry += " AND SUBSTRING(ACY_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("ACY"))))+") = SUBSTRING(U25_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("ACY"))))+")  "
	endif
	cQry += " AND ACY_GRPVEN = U25_GRPCLI "

	//NEGOCIACOES
	cQry += " LEFT JOIN "+RetSqlName("U44")+" U44 ON U44.D_E_L_E_T_ = ' ' AND U44_FILIAL = U25_FILIAL AND U44_FORMPG = U25_FORPAG AND U44_CONDPG = U25_CONDPG "

	cQry += " WHERE U25.D_E_L_E_T_ = ' ' "
	if !empty(aParamEnc[11])
		cQry += " AND U25_FILIAL = '"+aParamEnc[11]+"' "
	endif
	if !empty(aParamEnc[1])
		cQry += " AND U25_PRODUT = '" +aParamEnc[1]+"' "
	endif
	if !empty(aParamEnc[2])
		cQry += " AND U25_FORPAG = '" +aParamEnc[2]+"' "
	endif
	if !empty(aParamEnc[3])
		cQry += " AND U25_CONDPG = '" +aParamEnc[3]+"' "
	endif
	
	//preencheu cliente e grupo
	if !empty(aParamEnc[4]) .AND. !empty(aParamEnc[6])
		if empty(aParamEnc[5])
			cQry += " AND (U25_CLIENT = '" +aParamEnc[4]+"' OR (U25_GRPCLI <> '' AND U25_GRPCLI = '"+aParamEnc[6]+"') )"
		else
			cQry += " AND ((U25_CLIENT = '" +aParamEnc[4]+"' AND U25_LOJA = '"+aParamEnc[5]+"') OR (U25_GRPCLI <> '' AND U25_GRPCLI = '"+aParamEnc[6]+"') )"
		endif
	//so cliente
	elseif !empty(aParamEnc[4])
        cCpGrpCli := Posicione("SA1",1,xFilial("SA1")+aParamEnc[4]+Alltrim(aParamEnc[5]),"A1_GRPVEN")
        if !empty(cCpGrpCli)
            if empty(aParamEnc[5])
                cQry += " AND (U25_CLIENT = '" +aParamEnc[4]+"' OR (U25_GRPCLI <> '' AND U25_GRPCLI = '"+cCpGrpCli+"') )"
            else
                cQry += " AND ((U25_CLIENT = '" +aParamEnc[4]+"' AND U25_LOJA = '"+aParamEnc[5]+"') OR (U25_GRPCLI <> '' AND U25_GRPCLI = '"+cCpGrpCli+"') )"
            endif
        else
            if empty(aParamEnc[5])
                cQry += " AND U25_CLIENT = '" +aParamEnc[4]+"'"
            else
                cQry += " AND U25_CLIENT = '" +aParamEnc[4]+"' AND U25_LOJA = '"+aParamEnc[5]+"' "
            endif
        endif
	//so grupo
	elseif !empty(aParamEnc[6])
		cQry += " AND U25_GRPCLI = '"+aParamEnc[6]+"'"
	endif

	if !empty(aParamEnc[7])
		cQry += " AND U25_ADMFIN = '" +aParamEnc[7]+"' "
	endif

	cQry += " AND U25_DTINIC <= '"+DTOS(dDataBase)+"' "
	//cQry += " AND U25_HRINIC <= '"+SubStr(Time(),1,5)+"' "
	//cQry += " AND (U25_DTFIM = ' ' OR (U25_DTFIM >= '"+DTOS(dDataBase)+"' AND U25_HRFIM >= '"+SubStr(Time(),1,5)+"')) "
	cQry += " AND (U25_DTFIM = ' ' OR U25_DTFIM >= '"+DTOS(dDataBase)+"') "

	cQry += " ) TMP "
	cQry += " WHERE 1=1 "

	//filtros valor
	if aParamEnc[8]
		cQry += " AND TMP.U25_PRCVEN < TMP.D1_VUNIT "
	endif
	if aParamEnc[9] <> "1" //somente considera, caso nao marcou preco abaixo ultima nota
		cQry += " AND TMP.U25_PRCVEN "+cOperads[Val(aParamEnc[9])]+" " + cValtoChar(aParamEnc[10])
	endif

	If !("ORACLE" $ cSGBD)
		cQry += ")"
	endif

	//MemoWrite("c:\temp\RLOJA180.txt",cQry)
	
    if TCSqlExec(cQry) < 0
        Alert(TCSqlError())
		lRet := .F.
    endif

	(cAlias)->(DbGoTop())

Return lRet

//--------------------------------------------------------------------------------------
// Função para mostrar tela de legendas
//--------------------------------------------------------------------------------------
Static Function BtnLegenda()

	Local aLegenda := {}

	aadd(aLegenda,{"BR_VERDE"	, "Preço Venda Acima Ultima Compra"})
	aadd(aLegenda,{"BR_VERMELHO", "Preço Venda Abaixo Ultima Compra"})

	BrwLegenda("Legenda","Legenda",aLegenda)

Return aLegenda
