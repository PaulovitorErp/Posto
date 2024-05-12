#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'

/*/{Protheus.doc} TRETA49B
Rotina de Acompanhamento de Histórico de Preços Base

@param xParam Parameter Description
@return xRet Return Description
@author Danilo
@since 06/04/2020
/*/
User function TRETA49B()

    Local oDlg 		    := NIL
    Local aCoors 	    := FWGetDialogSize(oMainWnd)
    Local aSeekPrd 		:= {}
    Local lFilterOk 	:= .F.
    Local ni := 0

    Private aParamEnc 	:= {}
    Private aCampos 	:= {}
    Private aTipos      := {}
    Private oTable as object
    Private cAliasTemp as char
    Private cTableName as char

    //campos da grid
    aadd(aCampos,"U0C_FILIAL")
    aadd(aCampos,"U0C_PRODUT")
    aadd(aCampos,"B1_DESC")
    aadd(aCampos,"D1_VUNIT")
    aadd(aCampos,"U0C_PRCBAS")
    aadd(aCampos,"U0C_FORPAG")
    aadd(aCampos,"U0C_CONDPG")
    aadd(aCampos,"U44_DESCRI")
    aadd(aCampos,"U0C_ADMFIN")
    aadd(aCampos,"U0C_DTINIC")
    aadd(aCampos,"U0C_HRINIC")
    aadd(aCampos,"U0G_USHIST")
    aadd(aCampos,"U0G_DTHIST")
    aadd(aCampos,"U0G_HRHIST")

    for ni:=1 to len(aCampos)
        aadd(aTipos,GetSx3Cache(aCampos[ni],"X3_TIPO"))
    next ni

    aadd(aCampos,"ALIAS")
    aadd(aTipos,"C")
    

    //Cria tabela temporaria
    CriaTempAlias()

    //faz primeiro filtro
    FWMsgRun(,{|oSay| lFilterOk := DoFilter() },'Aguarde','Buscando registros...')

    if !lFilterOk
        Return
    endif

    DEFINE MSDIALOG oDlg FROM aCoors[1], aCoors[2] To aCoors[3], aCoors[4] PIXEL TITLE "Acompanhamento de Histórico de Preços - BASE" OF GetWndDefault() STYLE nOr(WS_VISIBLE, WS_POPUP)

    // Define o Browse
    oBrowse := FWBrowse():New(oDlg)
    oBrowse:SetAlias( cAliasTemp )
    oBrowse:SetDescription("Acompanhamento de Histórico de Preços Base")
    oBrowse:SetDataTable(.T.)
    //oBrowse:DisableReport()
    //oBrowse:DisableSeek()
    oBrowse:DisableSaveConfig()
    oBrowse:DisableConfig()

    // Botão pesquisar
    Aadd(aSeekPrd,{"Cod. Produto"	    , {{"","C",TamSX3("U0C_FILIAL")[1]+TamSX3("U0C_PRODUT")[1], 0, "Cod. Produto", PesqPict("U0C","U0C_PRODUT")}}, 	1, .T.})
    Aadd(aSeekPrd,{"Descricao Produto"	, {{"","C",TamSX3("U0C_FILIAL")[1]+TamSX3("B1_DESC")[1], 0,"Descrição Produto", PesqPict("SB1","B1_DESC")}}, 	2, .T.})
    oBrowse:SetSeek(, aSeekPrd)

    // Adiciona legenda no Browse
    oBrowse:AddLegend('(ALIAS=="U0C" .AND. DTOS(U0C_DTINIC)+U0C_HRINIC <= DTOS(DDATABASE)+SUBSTR(Time(),1,5))',"GREEN","Preço Vigente")
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
        if aCampos[nI] == "ALIAS"
            aTamSX3 := {3,0}
        else
            aTamSX3 := TamSX3(aCampos[nI])
        endif
        aAdd(aFields, {aCampos[nI], aTipos[nI], aTamSX3[1], aTamSX3[2]})
    next nI

    oTable:SetFields(aFields)

    //---------------------
    //Criação dos índices
    //---------------------
    oTable:AddIndex("01", {"U0C_FILIAL","U0C_PRODUT","U0C_FORPAG","U0C_CONDPG","U0C_ADMFIN"} )
    oTable:AddIndex("02", {"U0C_FILIAL","B1_DESC","U0C_FORPAG","U0C_CONDPG","U0C_ADMFIN"} )

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
        endif
        if aCampos[nI] == "ALIAS"
            cTitle := "Alias"
        endif

        bData := &("{|| " + aCampos[nI] +" }")

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
            iif(aCampos[nI] == "ALIAS", "@!", GetSx3Cache(aCampos[nI],"X3_PICTURE") ),;  
            nAlign, ;
            iif(aCampos[nI] == "ALIAS", 3, TamSX3(aCampos[nI])[1] ), ;
            iif(aCampos[nI] == "ALIAS", 0, TamSX3(aCampos[nI])[2] ), ;
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
    Local cQry := ""
    Local aPergs := {}
    Local cOperads := {"",">","<",">=","<=","="}
    Local nI
    Local cSGBD 	 	:= Upper(AllTrim(TcGetDB()))	// Guarda Gerenciador de banco de dados

    if empty(aParamEnc)
        aadd(aParamEnc, "1") //1=Ambos / 2=Vigente / 3=Não Vigente
        aadd(aParamEnc, Space(TamSX3("U0C_PRODUT")[1]))
        aadd(aParamEnc, Space(TamSX3("U0C_FORPAG")[1]))
        aadd(aParamEnc, Space(TamSX3("U0C_FORPAG")[1]))
		aadd(aParamEnc, Space(TamSX3("U0C_CONDPG")[1]))
        aadd(aParamEnc, .F.)
        aadd(aParamEnc, "1") //1=Ignora Filtro / 2=Maior que / 3=Menor que / 4=Maior ou Igual a / 5=Menor ou Igual a / 6=Igual a
        aadd(aParamEnc, 0)
        aadd(aParamEnc, cFilAnt)
        aadd(aParamEnc, CtoD(Space(8)))
    endif

    aAdd(aPergs,{2,"Preço Vigênte",aParamEnc[1],{"1=Ambos","2=Vigente","3=Não Vigente"},80,"",.F.})
    aAdd(aPergs,{1,"Produto",aParamEnc[2],PesqPict("U0C","U0C_PRODUT"),'.T.',"SB1",'.T.',80,.T.})
    aAdd(aPergs,{1,"Forma Pgto",aParamEnc[3],PesqPict("U0C","U0C_FORPAG"),'.T.',"24",'.T.',40,.F.})
    aAdd(aPergs,{1,"Condição Pgto",aParamEnc[4],PesqPict("U0C","U0C_CONDPG"),'.T.',"SE4",'.T.',40,.F.})
    aAdd(aPergs,{1,"Adm. Financeira",aParamEnc[5],PesqPict("U0C","U0C_ADMFIN"),'.T.',"SAE",'.T.',40,.F.})
    aAdd(aPergs,{4,"Considerar Preço ?",aParamEnc[6],"Abaixo Ultima NF Entrada",90,"",.F.})
    aAdd(aPergs,{2,"Preço Negociado",aParamEnc[7],{"1=Ignora Filtro","2=Maior que","3=Menor que","4=Maior ou Igual a","5=Menor ou Igual a","6=Igual a"},80,"",.F.})
    aAdd(aPergs,{1,"Valor",aParamEnc[8],PesqPict("U0C","U0C_PRCBAS"),'.T.',"",'.T.',50,.F.})
    aAdd(aPergs,{1,"Filial",aParamEnc[9],"@!",'.T.',"SM0",'.T.',50,.F.})
    aAdd(aPergs,{1,"A partir de Data",aParamEnc[10],"","","","",50,.F.})

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

    cQry := " SELECT TMP.*, ISNULL(B1_DESC,'') B1_DESC, ISNULL(U44_DESCRI,'') U44_DESCRI "
    cQry += " FROM  "
    cQry += " (  "

    //"1=Ambos","2=Vigente","3=Não Vigente"
    if aParamEnc[1] = "1" .OR. aParamEnc[1] = "2"

        cQry += " SELECT 'U0C' AS ALIAS, U0C_FILIAL, U0C_PRODUT, U0C_PRCBAS, "
        cQry += " U0C_FORPAG, U0C_CONDPG, U0C_ADMFIN, U0C_DTINIC, U0C_HRINIC, "
        cQry += " '' AS U0G_USHIST, '' AS U0G_DTHIST, '' AS U0G_HRHIST, "

        //ULTIMA COMPRA
        If "ORACLE" $ cSGBD //Oracle 
            cQry += " ISNULL((SELECT D1_VUNIT "
        else
            cQry += " ISNULL((SELECT TOP 1 D1_VUNIT "
        endif
        cQry += " FROM "+RetSqlName("SD1")+" SD1"
        cQry += " WHERE D_E_L_E_T_<> '*' "
        cQry += " AND D1_FILIAL = U0C_FILIAL "
        cQry += " AND D1_COD = U0C_PRODUT "
        cQry += " AND D1_TIPO = 'N'" //notas entrada normal
        If "ORACLE" $ cSGBD //Oracle 
		    cQry += " AND ROWNUM <= 1"
        endif
        cQry += " ORDER BY D1_EMISSAO DESC, D1_NUMSEQ DESC), 0) AS D1_VUNIT "
        
        cQry += " FROM "+RetSqlName("U0C")+" U0C "
        cQry += " WHERE U0C.D_E_L_E_T_ = ' ' "
   
        //FILTRO POR FILIAL
        if !empty(aParamEnc[9])
            cQry += " AND U0C_FILIAL = '"+xFilial("U0C",aParamEnc[9])+"' "
        endif
        if !empty(dtos(aParamEnc[10]))
            cQry += " AND U0C_DTINIC >= '"+dtos(aParamEnc[10])+"' "
        endif
        //FILTRO POR PRODUTO
        if !empty(aParamEnc[2])
            cQry += " AND U0C_PRODUT = '" +aParamEnc[2]+"' "
        endif
        //FILTRO POR FORMA DE PAGAMENTO
        if !empty(aParamEnc[3])
            cQry += " AND U0C_FORPAG = '" +aParamEnc[3]+"' "
        endif
        if !empty(aParamEnc[4])
            cQry += " AND U0C_CONDPG = '" +aParamEnc[4]+"' "
        endif
        if !empty(aParamEnc[5])
            cQry += " AND U0C_ADMFIN = '" +aParamEnc[5]+"' "
        endif

    endif

    //"1=Ambos","2=Vigente","3=Não Vigente"
    if aParamEnc[1] = "1" .OR. aParamEnc[1] = "3"
        if aParamEnc[1] = "1"
            cQry += " UNION "
        endif

        cQry += " SELECT 'U0G' AS ALIAS, U0G_FILIAL AS U0C_FILIAL, U0G_PRODUT AS U0C_PRODUT, U0G_PRCBAS AS U0C_PRCBAS, "
        cQry += " U0G_FORPAG AS U0C_FORPAG, U0G_CONDPG AS U0C_CONDPG, U0G_ADMFIN AS U0C_ADMFIN, U0G_DTINIC AS U0C_DTINIC, U0G_HRINIC AS U0C_HRINIC, "
        cQry += " U0G_USHIST, U0G_DTHIST, U0G_HRHIST, "
        
        //ULTIMA COMPRA
        If "ORACLE" $ cSGBD //Oracle 
            cQry += " ISNULL((SELECT D1_VUNIT "
        else
            cQry += " ISNULL((SELECT TOP 1 D1_VUNIT "
        endif
        cQry += " FROM "+RetSqlName("SD1")+" SD1"
        cQry += " WHERE D_E_L_E_T_<> '*' "
        cQry += " AND D1_FILIAL = U0G_FILIAL "
        cQry += " AND D1_COD = U0G_PRODUT "
        cQry += " AND D1_TIPO = 'N'" //notas entrada normal
        If "ORACLE" $ cSGBD //Oracle 
		    cQry += " AND ROWNUM <= 1"
        endif
        cQry += " ORDER BY D1_EMISSAO DESC, D1_NUMSEQ DESC), 0) AS D1_VUNIT "

        cQry += " FROM "+RetSqlName("U0G")+" U0G "
        cQry += " WHERE U0G.D_E_L_E_T_ = ' ' "
   
        //FILTRO POR FILIAL
        if !empty(aParamEnc[9])
            cQry += " AND U0G_FILIAL = '"+xFilial("U0G",aParamEnc[9])+"' "
        endif
        if !empty(dtos(aParamEnc[10]))
            cQry += " AND U0G_DTINIC >= '"+dtos(aParamEnc[10])+"' "
        endif
        //FILTRO POR PRODUTO
        if !empty(aParamEnc[2])
            cQry += " AND U0G_PRODUT = '" +aParamEnc[2]+"' "
        endif
        //FILTRO POR FORMA DE PAGAMENTO
        if !empty(aParamEnc[3])
            cQry += " AND U0G_FORPAG = '" +aParamEnc[3]+"' "
        endif
        if !empty(aParamEnc[4])
            cQry += " AND U0G_CONDPG = '" +aParamEnc[4]+"' "
        endif
        if !empty(aParamEnc[5])
            cQry += " AND U0G_ADMFIN = '" +aParamEnc[5]+"' "
        endif

    endif

    cQry += " ) TMP "


    //JUNCAO COM PRODUTOS: SB1
    cQry += " INNER JOIN "+RetSqlName("SB1")+" SB1 ON SB1.D_E_L_E_T_ = ' ' "
    if empty(xFilial("SB1")) //se for compartilhada total
        cQry += " AND B1_FILIAL = '"+xFilial("SB1")+"'"
    elseif Len(Alltrim(xFilial("SB1"))) == Len(Alltrim(xFilial("U0C"))) //se SB1 é exclusiva
        cQry += " AND B1_FILIAL = U0C_FILIAL "
    else //compartilhada parcialmente
        cQry += " AND SUBSTRING(B1_FILIAL,1,"+Len(Alltrim(xFilial("SB1")))+") = SUBSTRING(U0C_FILIAL,1,"+Len(Alltrim(xFilial("SB1")))+")  "
    endif
    cQry += " AND B1_COD = U0C_PRODUT  "

    //JUNCAO COM NEGOCIACOES: U44
    cQry += " LEFT JOIN "+RetSqlName("U44")+" U44 ON U44.D_E_L_E_T_ = ' ' AND U44_FILIAL = U0C_FILIAL AND U44_FORMPG = U0C_FORPAG AND U44_CONDPG = U0C_CONDPG "

    cQry += " WHERE 1=1 "

    //filtros valor
    if aParamEnc[6]
        cQry += " AND TMP.U0C_PRCBAS < TMP.D1_VUNIT "
    endif
    if aParamEnc[7] <> "1" //somente considera, caso nao marcou preco abaixo ultima nota
        cQry += " AND TMP.U0C_PRCBAS "+cOperads[Val(aParamEnc[7])]+" " + cValtoChar(aParamEnc[8])
    endif

    cQry += " ORDER BY U0C_FILIAL ASC, U0C_DTINIC DESC, U0C_HRINIC DESC "

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
        if AllTrim(cFilAnt) <> AllTrim((cMyAlias)->U0C_FILIAL)
        cFilAnt := (cMyAlias)->U0C_FILIAL
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
                if aCampos[nI] == "U44_DESCRI" .AND. empty((cAliasTemp)->U44_DESCRI)
                    (cAliasTemp)->U44_DESCRI := Posicione("SX5",1,xFilial("SX5")+"24"+(cMyAlias)->U0C_FORPAG,"X5_DESCRI")
                endif
            endif
        next

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
    aLegenda := {;
        {'BR_VERDE'		,"Preço Vigente"},;
        {'BR_VERMELHO'	,"Preço Não Vigente"} }

    BrwLegenda("Legenda","Legenda",aLegenda)

Return aLegenda
