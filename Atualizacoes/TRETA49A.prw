#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'

/*/{Protheus.doc} TRETA49A
Rotina de Acompanhamento de Histórico de Preços Negociados

@param xParam Parameter Description
@return xRet Return Description
@author Danilo
@since 06/04/2020
/*/
User function TRETA49A(_lCadCli)

    Local oDlg 		    := NIL
    Local aCoors 	    := FWGetDialogSize(oMainWnd)
    Local aSeekPrd 		:= {}
    Local lFilterOk 	:= .F.
    Local ni := 0
    Local lNgDesc := SuperGetMV("MV_XNGDESC",,.T.) //Ativa negociação pelo valor de desconto: U25_DESPBA
    Default _lCadCli		:= .F. 

    Private aParamEnc 	:= {}
    Private aCampos 	:= {}
    Private aTipos      := {}
    Private oTable as object
    Private cAliasTemp as char
    Private cTableName as char
    Private lCadCli := _lCadCli

    //campos da grid
    aadd(aCampos,"U25_FILIAL")
    aadd(aCampos,"U25_CLIENT")
    aadd(aCampos,"U25_LOJA")
    aadd(aCampos,"A1_NOME")
    aadd(aCampos,"U25_GRPCLI")
    aadd(aCampos,"ACY_DESCRI")
    aadd(aCampos,"U25_PRODUT")
    aadd(aCampos,"B1_DESC")
    aadd(aCampos,"D1_VUNIT")
    if lNgDesc
        aadd(aCampos,"U25_PRCBAS")
        aadd(aCampos,"U25_DESPBA")
    endif
    aadd(aCampos,"U25_PRCVEN")
    //aadd(aCampos,"DA1_PRCVEN")
    aadd(aCampos,"U25_FORPAG")
    aadd(aCampos,"U25_CONDPG")
    aadd(aCampos,"U44_DESCRI")
    aadd(aCampos,"U25_ADMFIN")
    aadd(aCampos,"U25_DTINIC")
    aadd(aCampos,"U25_HRINIC")
    aadd(aCampos,"U25_DTFIM")
    aadd(aCampos,"U25_HRFIM")
    aadd(aCampos,"U25_USER")
    if GetSx3Cache( "U25_PRBOLD" , "X3_CAMPO" ) == "U25_PRBOLD" //verifico se existe o campo no dicionário
        aadd(aCampos,"U25_PRBOLD")
        aadd(aCampos,"U25_PRVOLD")
        aadd(aCampos,"U25_DTINRE")
        aadd(aCampos,"U25_HRINRE")
        aadd(aCampos,"U25_DTHIST")
        aadd(aCampos,"U25_HRHIST")
        aadd(aCampos,"U25_USHIST")
    endif
    aadd(aCampos,"A1_XCOMERC")
    aadd(aCampos,"U25_BLQL")

    for ni:=1 to len(aCampos)
        aadd(aTipos,GetSx3Cache(aCampos[ni],"X3_TIPO"))
    next ni

    //Cria tabela temporaria
    CriaTempAlias()

    //faz primeiro filtro
    FWMsgRun(,{|oSay| lFilterOk := DoFilter() },'Aguarde','Buscando registros...')

    if !lFilterOk
        Return
    endif

    DEFINE MSDIALOG oDlg FROM aCoors[1], aCoors[2] To aCoors[3], aCoors[4] PIXEL TITLE "Acompanhamento de Histórico de Preços NEGOCIADO" OF GetWndDefault() STYLE nOr(WS_VISIBLE, WS_POPUP)

    // Define o Browse
    oBrowse := FWBrowse():New(oDlg)
    oBrowse:SetAlias( cAliasTemp )
    oBrowse:SetDescription("Acompanhamento de Histórico de Preços Negociados")
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
    oBrowse:AddLegend('U25_BLQL == "S"',"BLACK","Preço em aprovação por Alçada")
    oBrowse:AddLegend('(DTOS(U25_DTINIC)+U25_HRINIC <= DTOS(DDATABASE)+SUBSTR(Time(),1,5) .and. (empty(U25_DTFIM) .OR. DTOS(U25_DTFIM)+U25_HRFIM >= DTOS(DDATABASE)+SUBSTR(Time(),1,5) ))',"GREEN","Preço Vigente")
    oBrowse:AddLegend('.T.',"RED","Preço Não Vigente")

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
//-------------------------------------------------------------------
/*/{Protheus.doc} CriaTempAlias
Cria tabela temporaria no banco de dados
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function CriaTempAlias()

    Local nI
    Local aFields as array
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
        aTamSX3 := TamSX3(aCampos[nI])
        aAdd(aFields, {aCampos[nI], aTipos[nI], aTamSX3[1], aTamSX3[2]})
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
    cAliasTemp := oTable:GetAlias()

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
    Local bData
    Local cTitle := ""

    For nI := 1 to len(aCampos)

        nAlign := 1
        if aTipos[nI] == "N"
            nAlign := 2
        endif
        cTitle := Alltrim(RetTitle(aCampos[nI]))

        if aCampos[nI] == "D1_VUNIT"
            cTitle := "Preco U.Compra"
            //elseif aCampos[nI] == "DA1_PRCVEN"
            //    cTitle := "Prc. Tabela"
        endif

        if aCampos[nI] == "U25_USER"
            bData := &("{|| USRRETNAME(U25_USER)  }")
        elseif aCampos[nI] == "U25_USHIST"
            bData := &("{|| USRRETNAME(U25_USHIST)  }")
        else
            bData := &("{|| " + aCampos[nI] +" }")
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
            aTipos[nI],;
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
    //Local lTipoPreco := GetMv("MV_LJCNVDA")
    //Local cTabPrc := GetMv("MV_TABPAD")
    Local cQry := ""
    Local aPergs := {}
    Local cOperads := {"",">","<",">=","<=","="}
    Local nI
    Local cSGBD 	 	:= Upper(AllTrim(TcGetDB()))	// Guarda Gerenciador de banco de dados

    if empty(aParamEnc)
        if lCadCli
			aadd(aParamEnc, SA1->A1_COD)
			aadd(aParamEnc, SA1->A1_LOJA)
			aadd(aParamEnc, SA1->A1_GRPVEN)
		else
			aadd(aParamEnc, Space(TamSX3("U25_CLIENT")[1]))
			aadd(aParamEnc, Space(TamSX3("U25_LOJA")[1]))
			aadd(aParamEnc, Space(TamSX3("U25_GRPCLI")[1]))
		endif
        aadd(aParamEnc, "1") //1=Ambos / 2=Vigente / 3=Não Vigente
        aadd(aParamEnc, Space(TamSX3("U25_PRODUT")[1]))
        aadd(aParamEnc, Space(TamSX3("U25_FORPAG")[1]))
        aadd(aParamEnc, Space(TamSX3("U25_FORPAG")[1]))
		aadd(aParamEnc, Space(TamSX3("U25_CONDPG")[1]))
        aadd(aParamEnc, .F.)
        aadd(aParamEnc, "1") //1=Ignora Filtro / 2=Maior que / 3=Menor que / 4=Maior ou Igual a / 5=Menor ou Igual a / 6=Igual a
        aadd(aParamEnc, 0)
        aadd(aParamEnc, cFilAnt)
        aadd(aParamEnc, CtoD(Space(8)))
    endif

    aAdd(aPergs,{1,"Cliente",aParamEnc[1],PesqPict("U25","U25_CLIENT"),'.T.',"SA1",'!lCadCli',60,.F.})
    aAdd(aPergs,{1,"Loja",aParamEnc[2],PesqPict("U25","U25_LOJA"),'.T.',"",'!lCadCli',20,.F.})
    aAdd(aPergs,{1,"Grupo de Cliente",aParamEnc[3],PesqPict("U25","U25_GRPCLI"),'.T.',"ACY",'!lCadCli',60,.F.})
    aAdd(aPergs,{2,"Preço Vigênte",aParamEnc[4],{"1=Ambos","2=Vigente","3=Não Vigente"},80,"",.F.})
    aAdd(aPergs,{1,"Produto",aParamEnc[5],PesqPict("U25","U25_PRODUT"),'.T.',"SB1",'.T.',80,!lCadCli})
    aAdd(aPergs,{1,"Forma Pgto",aParamEnc[6],PesqPict("U25","U25_FORPAG"),'.T.',"24",'.T.',40,.F.})
    aAdd(aPergs,{1,"Condição Pgto",aParamEnc[7],PesqPict("U25","U25_CONDPG"),'.T.',"SE4",'.T.',40,.F.})
    aAdd(aPergs,{1,"Adm. Financeira",aParamEnc[8],PesqPict("U25","U25_ADMFIN"),'.T.',"SAE",'.T.',40,.F.})
    aAdd(aPergs,{4,"Considerar Preço ?",aParamEnc[9],"Abaixo Ultima NF Entrada",90,"",.F.})
    aAdd(aPergs,{2,"Preço Negociado",aParamEnc[10],{"1=Ignora Filtro","2=Maior que","3=Menor que","4=Maior ou Igual a","5=Menor ou Igual a","6=Igual a"},80,"",.F.})
    aAdd(aPergs,{1,"Valor",aParamEnc[11],PesqPict("U25","U25_PRCVEN"),'.T.',"",'.T.',50,.F.})
    aAdd(aPergs,{1,"Filial",aParamEnc[12],"@!",'.T.',"SM0",'.T.',50,.F.})
    aAdd(aPergs,{1,"A partir de Data",aParamEnc[13],"","","","",50,.F.})

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

    cQry := " SELECT TMP.* FROM "

    cQry += " ( SELECT U25_FILIAL, U25_CLIENT, U25_LOJA, "
    cQry +=   " ISNULL(A1_NOME,'') A1_NOME, U25_GRPCLI, ISNULL(ACY_DESCRI,'') ACY_DESCRI, U25_PRODUT, ISNULL(B1_DESC,'') B1_DESC, "

    //ULTIMA COMPRA
    If "ORACLE" $ cSGBD //Oracle 
        cQry += " ISNULL(SELECT D1_VUNIT "
    else
        cQry += " ISNULL(SELECT TOP 1 D1_VUNIT "
    endif
    cQry += " FROM "+RetSqlName("SD1")+" SD1"
    cQry += " WHERE D_E_L_E_T_<> '*' "
    cQry += " AND D1_FILIAL = U25_FILIAL "
    cQry += " AND D1_COD = U25_PRODUT "
    cQry += " AND D1_TIPO = 'N'" //notas entrada normal
    If "ORACLE" $ cSGBD //Oracle 
        cQry += " AND ROWNUM <= 1"
    endif
    cQry += " ORDER BY D1_EMISSAO DESC, D1_NUMSEQ DESC, 0) AS D1_VUNIT, "

    //PREÇO BASE E DESCONTO/ACRESCIMO
    if lNgDesc
        cQry += " 0 as U25_PRCBAS, U25_DESPBA, "
    endif

    if lNgDesc
        cQry += " 0 as U25_PRCVEN, "
    else
        cQry += " U25_PRCVEN, "
    endif

    //PRECO DE TABELA
    //if lTipoPreco
    //    cQry += " (SELECT TOP 1 DA1_PRCVEN "
    //    cQry += " FROM "+RetSqlName("DA1")+" DA1 "
    //    cQry += " WHERE DA1.D_E_L_E_T_ = ' ' "
    //    cQry += " AND DA1_FILIAL = U25_FILIAL "
    //    cQry += " AND DA1_CODTAB = '"+cTabPrc+"' "
    //    cQry += " AND DA1_CODPRO = U25_PRODUT "
    //    cQry += " AND DA1_DATVIG <= '"+DTOS(dDataBase)+"' "
    //    cQry += " ORDER BY DA1_DATVIG DESC) AS DA1_PRCVEN, "
    //else
    //    cQry += " (SELECT TOP 1 B0_PRV1 "
    //    cQry += " FROM "+RetSqlName("SB0")+" SB0 "
    //    cQry += " WHERE SB0.D_E_L_E_T_ = ' ' "
    //    cQry += " AND B0_FILIAL = U25_FILIAL "
    //    cQry += " AND B0_COD = U25_PRODUT) AS DA1_PRCVEN, "
    //endif

    //DEMAIS DADOS
    cQry += " U25_FORPAG, U25_CONDPG, ISNULL(U44_DESCRI,'') U44_DESCRI, U25_ADMFIN, "
    cQry += " U25_DTINIC, U25_HRINIC, U25_DTFIM, U25_HRFIM, U25_USER, "
    if GetSx3Cache( "U25_PRBOLD" , "X3_CAMPO" ) == "U25_PRBOLD" //verifico se existe o campo no dicionário
        cQry += " 0 as U25_PRBOLD, 0 as U25_PRVOLD, '' as U25_DTINRE, '' as U25_HRINRE, '' as U25_DTHIST, '' as U25_HRHIST, '' as U25_USHIST, "
    endif
    cQry += " ISNULL(A1_XCOMERC,'') A1_XCOMERC, U25_BLQL, U25_REPLIC "

    cQry += " FROM "+RetSqlName("U25")+" U25 "

    //JUNCAO COM PRODUTOS: SB1
    cQry += " INNER JOIN "+RetSqlName("SB1")+" SB1 ON SB1.D_E_L_E_T_ = ' ' "
    if empty(xFilial("SB1")) //se for compartilhada total
        cQry += " AND B1_FILIAL = '"+xFilial("SB1")+"'"
    elseif Len(Alltrim(xFilial("SB1"))) == Len(Alltrim(xFilial("U25"))) //se SB1 é exclusiva
        cQry += " AND B1_FILIAL = U25_FILIAL "
    else //compartilhada parcialmente
        cQry += " AND SUBSTRING(B1_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("SB1"))))+") = SUBSTRING(U25_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("SB1"))))+")  "
    endif
    cQry += " AND B1_COD = U25_PRODUT  "

    //JUNCAO COM CLIENTES: SA1
    cQry += " LEFT JOIN "+RetSqlName("SA1")+" SA1 ON SA1.D_E_L_E_T_ = ' ' "
    if empty(xFilial("SA1")) //se for compartilhada total
        cQry += " AND A1_FILIAL = '"+xFilial("SA1")+"'"
    elseif Len(Alltrim(xFilial("SA1"))) == Len(Alltrim(xFilial("U25"))) //se SA1 é exclusiva
        cQry += " AND A1_FILIAL = U25_FILIAL "
    else //compartilhada parcialmente
        cQry += " AND SUBSTRING(A1_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("SA1"))))+") = SUBSTRING(U25_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("SA1"))))+")  "
    endif
    cQry += " AND A1_COD = U25_CLIENT AND A1_LOJA = U25_LOJA "

    //JUNCAO COM GRUPO CLIENTES: ACY
    cQry += " LEFT JOIN "+RetSqlName("ACY")+" ACY ON ACY.D_E_L_E_T_ = ' ' "
    if empty(xFilial("ACY")) //se for compartilhada total
        cQry += " AND ACY_FILIAL = '"+xFilial("ACY")+"'"
    elseif Len(Alltrim(xFilial("ACY"))) == Len(Alltrim(xFilial("U25"))) //se ACY é exclusiva
        cQry += " AND ACY_FILIAL = U25_FILIAL "
    else //compartilhada parcialmente
        cQry += " AND SUBSTRING(ACY_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("ACY"))))+") = SUBSTRING(U25_FILIAL,1,"+cValToChar(Len(Alltrim(xFilial("ACY"))))+")  "
    endif
    cQry += " AND ACY_GRPVEN = U25_GRPCLI "

    //JUNCAO COM NEGOCIACOES: U44
    cQry += " LEFT JOIN "+RetSqlName("U44")+" U44 ON U44.D_E_L_E_T_ = ' ' AND U44_FILIAL = U25_FILIAL AND U44_FORMPG = U25_FORPAG AND U44_CONDPG = U25_CONDPG "

    cQry += " WHERE U25.D_E_L_E_T_ = ' ' "
    //FILTRO POR CLIENTE/GRUPO
    //preencheu cliente e grupo
	if !empty(aParamEnc[1]) .AND. !empty(aParamEnc[3])
		if empty(aParamEnc[2])
			cQry += " AND (U25_CLIENT = '" +aParamEnc[1]+"' OR (U25_GRPCLI <> '' AND U25_GRPCLI = '"+aParamEnc[3]+"') )"
		else
			cQry += " AND ((U25_CLIENT = '" +aParamEnc[1]+"' AND U25_LOJA = '"+aParamEnc[2]+"') OR (U25_GRPCLI <> '' AND U25_GRPCLI = '"+aParamEnc[3]+"') )"
		endif
	//so cliente
	elseif !empty(aParamEnc[1])
        cCpGrpCli := Posicione("SA1",1,xFilial("SA1")+aParamEnc[1]+Alltrim(aParamEnc[2]),"A1_GRPVEN")
        if !empty(cCpGrpCli)
            if empty(aParamEnc[2])
                cQry += " AND (U25_CLIENT = '" +aParamEnc[1]+"' OR (U25_GRPCLI <> '' AND U25_GRPCLI = '"+cCpGrpCli+"') )"
            else
                cQry += " AND ((U25_CLIENT = '" +aParamEnc[1]+"' AND U25_LOJA = '"+aParamEnc[2]+"') OR (U25_GRPCLI <> '' AND U25_GRPCLI = '"+cCpGrpCli+"') )"
            endif
        else
            if empty(aParamEnc[2])
                cQry += " AND U25_CLIENT = '" +aParamEnc[1]+"'"
            else
                cQry += " AND U25_CLIENT = '" +aParamEnc[1]+"' AND U25_LOJA = '"+aParamEnc[2]+"' "
            endif
        endif
	//so grupo
	elseif !empty(aParamEnc[3])
		cQry += " AND U25_GRPCLI = '"+aParamEnc[3]+"'"
	endif
    //FILTRO POR FILIAL
    if !empty(aParamEnc[12])
        cQry += " AND U25_FILIAL = '"+xFilial("U25",aParamEnc[12])+"' "
    endif
    if !empty(dtos(aParamEnc[13]))
        cQry += " AND U25_DATA >= '"+dtos(aParamEnc[13])+"' "
    endif
    //FILTRO POR PRODUTO
    if !empty(aParamEnc[5])
        cQry += " AND U25_PRODUT = '" +aParamEnc[5]+"' "
    endif
    //FILTRO POR FORMA DE PAGAMENTO
    if !empty(aParamEnc[6])
        cQry += " AND U25_FORPAG = '" +aParamEnc[6]+"' "
    endif
    if !empty(aParamEnc[7])
        cQry += " AND U25_CONDPG = '" +aParamEnc[7]+"' "
    endif
    if !empty(aParamEnc[8])
        cQry += " AND U25_ADMFIN = '" +aParamEnc[8]+"' "
    endif

    //"1=Ambos","2=Vigente","3=Não Vigente"
    if aParamEnc[4] = "1"
    elseif aParamEnc[4] = "2"
        cQry += " AND U25_DTINIC||U25_HRINIC <= '"+DTOS(dDataBase)+SubStr(Time(),1,5)+"' "
        cQry += " AND (U25_DTFIM = '        ' OR (U25_DTFIM||U25_HRFIM >= '"+DTOS(dDataBase)+""+SubStr(Time(),1,5)+"')) "
    elseif aParamEnc[4] = "3"
        cQry += " AND ( "
        cQry += " (U25_DTFIM <> '        ' AND (U25_DTFIM||U25_HRFIM < '"+DTOS(dDataBase)+""+SubStr(Time(),1,5)+"')) "
        cQry += " OR (U25_DTINIC||U25_HRINIC > '"+DTOS(dDataBase)+SubStr(Time(),1,5)+"')"
        cQry += " ) "
    endif

    cQry += " ) TMP "
    cQry += " WHERE 1=1 "

    //filtros valor
    if aParamEnc[9]
        cQry += " AND TMP.U25_PRCVEN < TMP.D1_VUNIT "
    endif
    if aParamEnc[10] <> "1" //somente considera, caso nao marcou preco abaixo ultima nota
        cQry += " AND TMP.U25_PRCVEN "+cOperads[Val(aParamEnc[10])]+" " + cValtoChar(aParamEnc[11])
    endif

    cQry += " ORDER BY U25_FILIAL ASC, U25_REPLIC DESC "

    //fazer select e add registros retornados no acols
    cMyAlias := "QRYTMP"
    If Select(cMyAlias) > 0
        (cMyAlias)->(DbCloseArea())
    Endif

    cQry := ChangeQuery(cQry)
    TcQuery cQry NEW Alias "QRYTMP"

    (cMyAlias)->(DbGoTop())
    While (cMyAlias)->(!EOF())

        //ajusta o cfilant
        if AllTrim(cFilAnt) <> AllTrim((cMyAlias)->U25_FILIAL)
        cFilAnt := (cMyAlias)->U25_FILIAL
        endif

        //------------------------------------------
        //Inserção de dados na FWTemporaryTable
        //------------------------------------------
        (cAliasTemp)->(DBAppend())

        //Pega todos os campos para efetuar a inserção
        for nI := 1 to Len(aCampos)
            if aTipos[nI] = 'D'
                &('(cAliasTemp)->'+aCampos[nI]) := &('StoD((cMyAlias)->'+aCampos[nI]+')')
            else
                &('(cAliasTemp)->'+aCampos[nI]) := &('(cMyAlias)->'+aCampos[nI])
            endif
        next

        (cAliasTemp)->U25_USER := (cMyAlias)->U25_USER

        if lNgDesc
            nPrcBas := U_URetPrBa((cMyAlias)->U25_PRODUT, (cMyAlias)->U25_FORPAG, (cMyAlias)->U25_CONDPG, (cMyAlias)->U25_ADMFIN, 0, StoD((cMyAlias)->U25_DTINIC), (cMyAlias)->U25_HRINIC)
            (cAliasTemp)->U25_PRCBAS := nPrcBas
            (cAliasTemp)->U25_PRCVEN := nPrcBas - (cMyAlias)->U25_DESPBA
        endif

        if GetSx3Cache( "U25_PRBOLD" , "X3_CAMPO" ) == "U25_PRBOLD" //verifico se existe o campo no dicionário
            //U_URetU0G -> [1]U0G_PRCBAS, [2]U0G_DTINIC, [3]U0G_HRINIC, [4]U0G_USHIST, [5]U0G_DTHIST, [6]U0G_HRHIST
            lPAtivo := ((cMyAlias)->U25_DTINIC+(cMyAlias)->U25_HRINIC <= DTOS(DDATABASE)+SUBSTR(Time(),1,5) .and. (empty((cMyAlias)->U25_DTFIM) .OR. (cMyAlias)->U25_DTFIM+(cMyAlias)->U25_HRFIM >= DTOS(DDATABASE)+SUBSTR(Time(),1,5) ))
            aRetU0G := U_URetU0G((cMyAlias)->U25_PRODUT, (cMyAlias)->U25_FORPAG, (cMyAlias)->U25_CONDPG, (cMyAlias)->U25_ADMFIN, {StoD((cMyAlias)->U25_DTINIC),(cMyAlias)->U25_HRINIC,StoD((cMyAlias)->U25_DTFIM),(cMyAlias)->U25_HRFIM}, lPAtivo)
            (cAliasTemp)->U25_PRBOLD := aRetU0G[1]
            (cAliasTemp)->U25_PRVOLD := Iif(aRetU0G[1]=0,0,(aRetU0G[1] - (cMyAlias)->U25_DESPBA))
            (cAliasTemp)->U25_DTINRE := aRetU0G[2]
            (cAliasTemp)->U25_HRINRE := aRetU0G[3]
            (cAliasTemp)->U25_USHIST := aRetU0G[4]
            (cAliasTemp)->U25_DTHIST := aRetU0G[5]
            (cAliasTemp)->U25_HRHIST := aRetU0G[6]
        endif

        (cAliasTemp)->A1_XCOMERC := iif(empty((cMyAlias)->U25_GRPCLI),(cMyAlias)->A1_XCOMERC, Posicione('SA1',6,xFilial('SA1')+(cMyAlias)->U25_GRPCLI,'A1_XCOMERC') )

        (cAliasTemp)->(DBCommit())

        (cMyAlias)->(DbSkip())
    EndDo

    (cAliasTemp)->(DbGoTop())

Return lRet

//--------------------------------------------------------------------------------------
// Função para mostrar tela de legendas
//--------------------------------------------------------------------------------------
Static Function BtnLegenda()

    Local aLegenda := {}

    //cor a legenda: Preto (preço bloqueado), Verde (preço ativo) ou Vermelho (preço vencido)
    aLegenda := {	{'BR_PRETO'		,"Preço em aprovação por Alçada"},;
        {'BR_VERDE'		,"Preço Vigente"},;
        {'BR_VERMELHO'	,"Preço Não Vigente"} }

    BrwLegenda("Legenda","Legenda",aLegenda)

Return aLegenda
