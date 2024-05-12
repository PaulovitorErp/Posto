#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOPCONN.CH'

/*/{Protheus.doc} TRETA022
Cadastro de Regras de Negociação de Clientes

@author Pablo Cavalcante
@since 25/04/2014
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function TRETA022()
	Local oBrowse

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('U52')
	oBrowse:SetDescription( 'Regra de Negociação de Clientes / Grupo / Classe / Segmento' )

	oBrowse:Activate()

Return NIL

//-------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar'   ACTION 'VIEWDEF.TRETA022' 	OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Incluir'      ACTION 'VIEWDEF.TRETA022' 	OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE 'Alterar'      ACTION 'VIEWDEF.TRETA022' 	OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE 'Excluir'      ACTION 'VIEWDEF.TRETA022' 	OPERATION 5 ACCESS 0
	//ADD OPTION aRotina Title 'Replicar'   	ACTION 'U_TRET022F' 		OPERATION 7 ACCESS 0
	if cFilAnt == xFilial("U53") //adiciono menu somente se tabela for exclusiva
		ADD OPTION aRotina Title 'Replicar p/ Filiais'	ACTION 'U_TRET022R' 		OPERATION 7 ACCESS 0
	endif
	ADD OPTION aRotina TITLE 'Imprimir'     ACTION 'VIEWDEF.TRETA022' 	OPERATION 8 ACCESS 0
	ADD OPTION aRotina TITLE 'Copiar'		ACTION 'VIEWDEF.TRETA022' 	OPERATION 9 ACCESS 0
	ADD OPTION aRotina Title 'Configurar Faturamento' Action "U_TRETA17D('U88',Recno(),3,'CADNEG')" OPERATION 10 ACCESS 0

Return aRotina

//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ModelDef()

// Cria a estrutura a ser usada no Modelo de Dados
	Local oStruU52 := FWFormStruct( 1, 'U52', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oStruU53 := FWFormStruct( 1, 'U53', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oModel

	//nao permitir alterar campos chave depois de ja gravado
	oStruU53:SetProperty("U53_FORMPG", MODEL_FIELD_WHEN, {|oMdl, cFld| WhenChave(oMdl, cFld) })
	oStruU53:SetProperty("U53_CONDPG", MODEL_FIELD_WHEN, {|oMdl, cFld| WhenChave(oMdl, cFld) })

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('TRETM022', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formul·rio de ediÁ?o por campo
	oModel:AddFields( 'U52MASTER', /*cOwner*/, oStruU52, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "U52_FILIAL" , "U52_CODCLI", "U52_LOJA", "U52_GRPVEN", "U52_SATIV1", "U52_CLASSE" })

	// Adiciona ao modelo uma componente de grid
	oModel:AddGrid( 'U53DETAIL', 'U52MASTER', oStruU53 )

	// Faz relacionamento entre os componentes do model
	oModel:SetRelation( 'U53DETAIL', { {'U53_FILIAL', 'xFilial( "U53" )'}, {"U53_CODCLI", "U52_CODCLI"}, {"U53_LOJA", "U52_LOJA"}, {"U53_GRPVEN", "U52_GRPVEN"}, {"U53_CLASSE", "U52_CLASSE"}, {"U53_SATIV1", "U52_SATIV1"} }, U53->( IndexKey( 1 ) ) )

	// Liga o controle de nao repeticao de linha
	oModel:GetModel( 'U53DETAIL' ):SetUniqueLine( { 'U53_ITEM' } )

	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Negociação de Pagamento de Clientes / Grupo / Classe / Segmento' )

	// Seto a propriedade de não obrigatoriedade do preenchimento do grid
	oModel:GetModel('U53DETAIL'):SetOptional(.T.)

	// Adiciona a descrição dos Componentes do Modelo de Dados
	oModel:GetModel( 'U52MASTER' ):SetDescription( 'Dados da Negociação' )
	oModel:GetModel( 'U53DETAIL' ):SetDescription( 'Itens da Negociação de Pagamento' )

Return oModel

//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function ViewDef()
// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oModel   := FWLoadModel( 'TRETA022' )
// Cria a estrutura a ser usada na View
	Local oStruU52 := FWFormStruct( 2, 'U52' ) //Local oStruU52 := FWFormStruct( 2, 'U52', { |cCampo| COMP11STRU(cCampo) } )
	Local oStruU53 := FWFormStruct( 2, 'U53' )
	Local oView

	//Remove campos da estrutura
	oStruU53:RemoveField( "U53_CODCLI" )
	oStruU53:RemoveField( "U53_LOJA" )
	oStruU53:RemoveField( "U53_GRPVEN" )
	oStruU53:RemoveField( "U53_CLASSE" )
	oStruU53:RemoveField( "U53_SATIV1" )

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados ser· utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_U52', oStruU52, 'U52MASTER' )

	//Adiciona no nosso View um controle do tipo Grid (antiga Getdados)
	oView:AddGrid( 'VIEW_U53', oStruU53, 'U53DETAIL' )

	// Cria um "box" horizontal para receber cada elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR', 35 )
	oView:CreateHorizontalBox( 'INFERIOR', 65 )

	// Relaciona o identificador (ID) da View com o "box" para exibição
	oView:SetOwnerView( 'VIEW_U52' , 'SUPERIOR' )
	oView:SetOwnerView( 'VIEW_U53' , 'INFERIOR' )

	// titulo dos componentes
	oView:EnableTitleView('VIEW_U52' ,/*'cabecalho'*/)
	oView:EnableTitleView('VIEW_U53' ,/*'itens'*/)

	// Define campos que terao Auto Incremento
	oView:AddIncrementField( 'VIEW_U53', 'U53_ITEM' )

	bBloco := {|oView| IniciCli(oView)}
	oView:SetAfterViewActivate(bBloco)

Return oView

//-------------------------------------------------------------------
/*/{Protheus.doc} IniciCli
Inicializa variaveis da tela, com dados do cliente posicionado.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function IniciCli(oView)
	Local nOperation 	:= oView:GetOperation()

	If nOperation == 3
		If AllTrim(FunName()) == "MATA030" .or. AllTrim(FunName()) == "CRMA980" //Origem Cad. Cliente

			FwFldPut("U52_CODCLI",__cCli,,,,.T.)
			FwFldPut("U52_LOJA",__cLojaCli,,,,.T.)
			FwFldPut("U52_NOME",Posicione("SA1",1,xFilial("SA1")+__cCli+__cLojaCli,"A1_NOME"))

			oView:Refresh()

		EndIf
	EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} TRET022A
Funcao de validacao do campo U52_CODCLI
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRET022A()
	Local aArea    := GetArea()
	Local aAreaU52 := U52->(GetArea())
	Local lReturn  := .T.

	dbselectarea("U52")
	U52->(dbsetorder(1)) //U52_FILIAL+U52_CODCLI+U52_LOJA+U52_GRPVEN+U52_CLASSE+U52_SATIV1
	If U52->(dbseek(xFilial("U52")+M->U52_CODCLI+M->U52_LOJA+M->U52_GRPVEN+M->U52_CLASSE+M->U52_SATIV1))

		lReturn  := .F.

		if !empty(M->U52_CODCLI)
			cDados := "o Cliente: "+M->U52_CODCLI+"/"+M->U52_LOJA+" - "+Posicione("SA1",1,xFilial("SA1")+M->U52_CODCLI+M->U52_LOJA,"A1_NOME")
		ElseIf !empty(M->U52_GRPVEN)
			cDados := "o Grupo de Cliente: "   +M->U52_GRPVEN+" - "+Posicione("ACY",1,xFilial("ACY")+M->U52_GRPVEN,"ACY_DESCRI")
		ElseIf !empty(M->U52_CLASSE)
			cDados := "a Classe de Cliente: "  +M->U52_CLASSE+" - "+Posicione("UF6",1,xFilial("UF6")+M->U52_CLASSE,"UF6_DESC")
		ElseIf !empty(M->U52_SATIV1)
			cDados := "o Segmento de Cliente: "+M->U52_SATIV1+" - "+Posicione("SX5",1,xFilial("SX5")+"T3"+M->U52_SATIV1,"X5_DESCRI")
		endif

		Help(,,"Atenção",,"Ja existe uma Regra de Negociação de Pagamento para "+cDados+".",1,0,,,,,,{""})

	EndIf

	if (AllTrim(ReadVar()) == "M->U52_CODCLI" .and. !empty(M->U52_CODCLI)) .or. (AllTrim(ReadVar()) == "M->U52_LOJA" .and. !empty(M->U52_LOJA))
		M->U52_GRPVEN := ""
		M->U52_DESGRP := ""
		M->U52_CLASSE := ""
		M->U52_DESCCL := ""
		M->U52_SATIV1 := ""
		M->U52_DESCAT := ""
	ElseIf AllTrim(ReadVar()) == "M->U52_GRPVEN" .and. !empty(M->U52_GRPVEN)
		M->U52_CODCLI := ""
		M->U52_LOJA   := ""
		M->U52_NOME   := ""
		M->U52_CLASSE := ""
		M->U52_DESCCL := ""
		M->U52_SATIV1 := ""
		M->U52_DESCAT := ""
	ElseIf AllTrim(ReadVar()) == "M->U52_CLASSE" .and. !empty(M->U52_CLASSE)
		M->U52_CODCLI := ""
		M->U52_LOJA   := ""
		M->U52_NOME   := ""
		M->U52_GRPVEN := ""
		M->U52_DESGRP := ""
		M->U52_SATIV1 := ""
		M->U52_DESCAT := ""
	ElseIf AllTrim(ReadVar()) == "M->U52_SATIV1" .and. !empty(M->U52_SATIV1)
		M->U52_CODCLI := ""
		M->U52_LOJA   := ""
		M->U52_NOME   := ""
		M->U52_GRPVEN := ""
		M->U52_DESGRP := ""
		M->U52_CLASSE := ""
		M->U52_DESCCL := ""
	endif

	RestArea(aAreaU52)
	RestArea(aArea)
Return(lReturn)

//-------------------------------------------------------------------
/*/{Protheus.doc} TRET022B
	
@author pablocavalcante
@since 06/06/2014
@version 1.0

@description

Filtro Consulta Padrao U44ES -> U53_FORMPG

/*/
User Function TRET022B()
	Local lRet       := .T.
	Local cFormPg    := Space(TamSX3("U53_FORMPG")[1])
	Local oModel     := FWModelActive() //FWLoadModel( 'TRETA022' )
	Local oModelU53  := oModel:GetModel( 'U53DETAIL' )
	//Local nLinha     := oModelU53:nLine
	//Local nPosFormPg := aScan(oModelU53:aHeader,{|x| AllTrim(x[2])=="U53_FORMPG"})

	cFormPg := oModelU53:GetValue("U53_FORMPG") //oModelU53:aCols[nLinha][nPosFormPg]
	lRet    := (U44->U44_FORMPG == cFormPg)

Return (lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} TRET022C

@author pablocavalcante
@since 06/06/2014
@version 1.0

@description

Validacao de Campo -> U53_FORMPG e U53_CONDPG
e preenchimento do campo U53_DESCRI

/*/
User Function TRET022C()
	Local aAreaU44   := U44->(GetArea())
	Local lRet       := .T.
	Local cFormPg    := Space(TamSX3("U53_FORMPG")[1])
	Local cCondPg    := Space(TamSX3("U53_CONDPG")[1])
	Local oModel     := FWModelActive() //FWLoadModel('TRETA022')
	Local oModelU53  := oModel:GetModel('U53DETAIL')
	//Local nLinha     := oModelU53:nLine
	//Local nPosFormPg := aScan(oModelU53:aHeader,{|x| AllTrim(x[2])=="U53_FORMPG"})
	//Local nPosCondPg := aScan(oModelU53:aHeader,{|x| AllTrim(x[2])=="U53_CONDPG"})

	DbSelectArea("U44")
	U44->(DbSetOrder(1)) //U44_FILIAL+U44_FORMPG+U44_CONDPG

	cFormPg := oModelU53:GetValue("U53_FORMPG")
	cCondPg := oModelU53:GetValue("U53_CONDPG")
	oModelU53:SetValue('U53_DESCRI','')

	If empty(cCondPg) .and. !empty(cFormPg)
		lRet := U44->(dbseek(xFilial("U44")+cFormPg))
		oModelU53:SetValue('U53_DESCRI',U44->U44_DESCRI)
	ElseIf !empty(cCondPg) .and. !empty(cFormPg)
		lRet := U44->(dbseek(xFilial("U44")+cFormPg+cCondPg))
		oModelU53:SetValue('U53_DESCRI',U44->U44_DESCRI)
	EndIf

	RestArea(aAreaU44)
Return (lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} TRET022D
	
@author pablocavalcante
@since 06/06/2014
@version 1.0

@description

Validacao de Negociação de Pagamento que NÃO é padrão. Verifica se tem Regra de Neg. Pgto. Cliente
Passar Forma de Pagamento, Condição de Pagamento, Cliente, Loja e Produto

Retorno: .T. - se é permitido usar a Negociação de Pagamento para o cliente e produto
		 .F. - se não é permitido usar Negociação de Pagamento para o cliente e produto

/*/
User Function TRET022D(cFormPg,cCondPg,cCodCli,cLojCli,cProduto,lHelp,cHelp,cGrpCli)

	Local lRet 		:= .T.
	Local cGrpProd 	:= ""
	Local cTpRegra 	:= ""
	Local lTemRegra := .F.
	Default lHelp 	:= .T.
	Default cHelp   := ""
	Default cGrpCli := ""

	if empty(cFormPg) .or. empty(cCondPg) .or. empty(cCodCli+cLojCli+cGrpCli) //.or. empty(cProduto)
		if lHelp
			Help(,,"Atenção",,"TRET022D: Parametros passados incorretamente.",1,0,,,,,,{""})
		else
			cHelp += "TRET022D: Parametros passados incorretamente. " + CRLF
		endif
		return .F.
	endif

	if empty(cGrpCli)
		cGrpCli 	:= Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_GRPVEN")
		cClasse     := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_XCLASSE")
		cAtivid     := Posicione("SA1",1,xFilial("SA1")+cCodCli+cLojCli,"A1_SATIV1")
	else
		cClasse     := ""
		cAtivid     := ""
	endif
	if !empty(cProduto)
		cGrpProd 	:= Posicione("SB1",1,xFilial("SB1")+cProduto,"B1_GRUPO")
	endif

	//verifica se tem exceçao para o segmento cliente
	if !empty(cAtivid)
		cTpRegra := GetTpRegra(cFormPg,cCondPg,"","","","",cAtivid,"","")
		if cTpRegra == "E" //se for exceção
			if lHelp
				Help('',1,'FORMPAG',,"Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Segmento de Cliente: "+cAtivid+".",1,0)
			else
				cHelp += "TRET022D: FORMPAG - Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Segmento de Cliente: "+cAtivid+"." + CRLF
			endif
			return .F.
		ElseIf !lTemRegra .AND. cTpRegra == "R" //se por regra
			lTemRegra := .T.
		endif
	endif

	//verifica se tem exceçao para o segmento cliente e grupo de produto
	if !empty(cAtivid) .AND. !empty(cGrpProd)
		cTpRegra := GetTpRegra(cFormPg,cCondPg,"","","","",cAtivid,"",cGrpProd)
		if cTpRegra == "E" //se for exceção
			if lHelp
				Help('',1,'FORMPAG',,"Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Segmento de Cliente: "+cAtivid+", e Grupo de Produto: "+cGrpProd+".",1,0)
			else
				cHelp += "TRET022D: FORMPAG - Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Segmento de Cliente: "+cAtivid+", e Grupo de Produto: "+cGrpProd+"." + CRLF
			endif
			return .F.
		ElseIf !lTemRegra .AND. cTpRegra == "R" //se por regra
			lTemRegra := .T.
		endif
	endif

	//verifica se tem exceçao para o segmento cliente e produto
	if !empty(cAtivid) .AND. !empty(cProduto)
		cTpRegra := GetTpRegra(cFormPg,cCondPg,"","","","",cAtivid,cProduto,"")
		if cTpRegra == "E" //se for exceção
			if lHelp
				Help('',1,'FORMPAG',,"Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Segmento de Cliente: "+cAtivid+", e Produto: "+cProduto+".",1,0)
			else
				cHelp += "TRET022D: FORMPAG - Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Segmento de Cliente: "+cAtivid+", e Produto: "+cProduto+"." + CRLF
			endif
			return .F.
		ElseIf !lTemRegra .AND. cTpRegra == "R" //se por regra
			lTemRegra := .T.
		endif
	endif

	//verifica se tem exceçao para a classe de cliente
	if !empty(cClasse)
		cTpRegra := GetTpRegra(cFormPg,cCondPg,"","","",cClasse,"","","")
		if cTpRegra == "E" //se for exceção
			if lHelp
				Help('',1,'FORMPAG',,"Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Classe de Cliente: "+cClasse+".",1,0)
			else
				cHelp += "TRET022D: FORMPAG - Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Classe de Cliente: "+cClasse+"." + CRLF
			endif
			return .F.
		ElseIf !lTemRegra .AND. cTpRegra == "R" //se por regra
			lTemRegra := .T.
		endif
	endif

	//verifica se tem exceçao para a classe de cliente e grupo de produto
	if !empty(cClasse) .AND. !empty(cGrpProd)
		cTpRegra := GetTpRegra(cFormPg,cCondPg,"","","",cClasse,"","",cGrpProd)
		if cTpRegra == "E" //se for exceção
			if lHelp
				Help('',1,'FORMPAG',,"Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Classe de Cliente: "+cClasse+", e Grupo de Produto: "+cGrpProd+".",1,0)
			else
				cHelp += "TRET022D: FORMPAG - Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Classe de Cliente: "+cClasse+", e Grupo de Produto: "+cGrpProd+"." + CRLF
			endif
			return .F.
		ElseIf !lTemRegra .AND. cTpRegra == "R" //se por regra
			lTemRegra := .T.
		endif
	endif

	//verifica se tem exceçao para a classe de cliente e produto
	if !empty(cClasse) .AND. !empty(cProduto)
		cTpRegra := GetTpRegra(cFormPg,cCondPg,"","","",cClasse,"",cProduto,"")
		if cTpRegra == "E" //se for exceção
			if lHelp
				Help('',1,'FORMPAG',,"Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Classe de Cliente: "+cClasse+", e Produto: "+cProduto+".",1,0)
			else
				cHelp += "TRET022D: FORMPAG - Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Classe de Cliente: "+cClasse+", e Produto: "+cProduto+"." + CRLF
			endif
			return .F.
		ElseIf !lTemRegra .AND. cTpRegra == "R" //se por regra
			lTemRegra := .T.
		endif
	endif

	//verifica se tem exceçao para o grupo cliente
	if !empty(cGrpCli)
		cTpRegra := GetTpRegra(cFormPg,cCondPg,"","",cGrpCli,"","","","")
		if cTpRegra == "E" //se for exceção
			if lHelp
				Help('',1,'FORMPAG',,"Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Grupo de Cliente: "+cGrpCli+".",1,0)
			else
				cHelp += "TRET022D: FORMPAG - Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Grupo de Cliente: "+cGrpCli+"." + CRLF
			endif
			return .F.
		ElseIf !lTemRegra .AND. cTpRegra == "R" //se por regra
			lTemRegra := .T.
		endif
	endif

	//verifica se tem exceçao para o grupo cliente e grupo de produto
	if !empty(cGrpCli) .AND. !empty(cGrpProd)
		cTpRegra := GetTpRegra(cFormPg,cCondPg,"","",cGrpCli,"","","",cGrpProd)
		if cTpRegra == "E" //se for exceção
			if lHelp
				Help('',1,'FORMPAG',,"Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Grupo de Cliente: "+cGrpCli+", e Grupo de Produto: "+cGrpProd+".",1,0)
			else
				cHelp += "TRET022D: FORMPAG - Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Grupo de Cliente: "+cGrpCli+", e Grupo de Produto: "+cGrpProd+"." + CRLF
			endif
			return .F.
		ElseIf !lTemRegra .AND. cTpRegra == "R" //se por regra
			lTemRegra := .T.
		endif
	endif

	//verifica se tem exceçao para o grupo cliente e produto
	if !empty(cGrpCli) .AND. !empty(cProduto)
		cTpRegra := GetTpRegra(cFormPg,cCondPg,"","",cGrpCli,"","",cProduto,"")
		if cTpRegra == "E" //se for exceção
			if lHelp
				Help('',1,'FORMPAG',,"Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Grupo de Cliente: "+cGrpCli+", e Produto: "+cProduto+".",1,0)
			else
				cHelp += "TRET022D: FORMPAG - Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, por Grupo de Cliente: "+cGrpCli+", e Produto: "+cProduto+"." + CRLF
			endif
			return .F.
		ElseIf !lTemRegra .AND. cTpRegra == "R" //se por regra
			lTemRegra := .T.
		endif
	endif

	//verifica se tem exceçao para o cliente
	if !empty(cCodCli+cLojCli)
		cTpRegra := GetTpRegra(cFormPg,cCondPg,cCodCli,cLojCli,"","","","","")
		if cTpRegra == "E" //se for exceção
			if lHelp
				Help('',1,'FORMPAG',,"Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, para o Cliente: "+cCodCli+"/"+cLojCli+".",1,0)
			else
				cHelp += "TRET022D: FORMPAG - Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, para o Cliente: "+cCodCli+"/"+cLojCli+"." + CRLF
			endif
			return .F.
		ElseIf !lTemRegra .AND. cTpRegra == "R" //se por regra
			lTemRegra := .T.
		endif


		//verifica se tem exceçao para o cliente e grupo de produto
		if !empty(cGrpProd)
			cTpRegra := GetTpRegra(cFormPg,cCondPg,cCodCli,cLojCli,"","","","",cGrpProd)
			if cTpRegra == "E" //se for exceção
				if lHelp
					Help('',1,'FORMPAG',,"Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, para o Cliente: "+cCodCli+"/"+cLojCli+", e Grupo de Produto: "+cGrpProd+".",1,0)
				else
					cHelp += "TRET022D: FORMPAG - Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, para o Cliente: "+cCodCli+"/"+cLojCli+", e Grupo de Produto: "+cGrpProd+"." + CRLF
				endif
				return .F.
			ElseIf !lTemRegra .AND. cTpRegra == "R" //se por regra
				lTemRegra := .T.
			endif
		endif

		//verifica se tem exceçao para o cliente e produto
		if !empty(cProduto)
			cTpRegra := GetTpRegra(cFormPg,cCondPg,cCodCli,cLojCli,"","","",cProduto,"")
			if cTpRegra == "E" //se for exceção
				if lHelp
					Help('',1,'FORMPAG',,"Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, para o Cliente: "+cCodCli+"/"+cLojCli+", e Produto: "+cProduto+".",1,0)
				else
					cHelp += "TRET022D: FORMPAG - Existe uma exceção que bloqueia o uso desta Negociação de Pagamento, para o Cliente: "+cCodCli+"/"+cLojCli+", e Produto: "+cProduto+"." + CRLF
				endif
				return .F.
			ElseIf !lTemRegra .AND. cTpRegra == "R" //se por regra
				lTemRegra := .T.
			endif
		endif
	endif

	//se chegou aqui, é porque não tem exceção, então tem que ter Regra.
	if !lTemRegra
		if lHelp
			Help('',1,'FORMPAG',,"Não há regras que permitam o uso desta Negociação de Pagamento para o Cliente: "+cCodCli+"/"+cLojCli+", e Produto: "+cProduto+".",1,0)
		else
			cHelp += "TRET022D: FORMPAG - Não há regras que permitam o uso desta Negociação de Pagamento para o "+iif(!empty(cCodCli+cLojCli),"Cliente: "+cCodCli+"/"+cLojCli,"Grupo de Cliente: "+cGrpCli)+", e Produto: "+cProduto+"." + CRLF
		endif
		return .F.
	endif

Return (lRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} GetTpRegra
funçao que faz o select para buscar regra
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function GetTpRegra(cFormPg,cCondPg,cCodCli,cLojCli,cGrpCli,cClasse,cAtivid,cProduto,cGrpProd)
	Local aArea     := GetArea()
	Local cTpRegra  := ""
	Local cCondicao := ""
	Local bCondicao

	cCondicao := " U53_FILIAL = '"+xFilial("U53")+"'"
	cCondicao += " .AND. alltrim(U53_FORMPG) == '"+alltrim(cFormPg)+"'"
	cCondicao += " .AND. alltrim(U53_CONDPG) == '"+alltrim(cCondPg)+"'"
	cCondicao += " .AND. alltrim(U53_GRPVEN) == '"+alltrim(cGrpCli)+"'"
	cCondicao += " .AND. alltrim(U53_CODCLI) == '"+alltrim(cCodCli)+"'"
	cCondicao += " .AND. alltrim(U53_LOJA)   == '"+alltrim(cLojCli)+"'"
	cCondicao += " .AND. alltrim(U53_CLASSE) == '"+alltrim(cClasse)+"'"
	cCondicao += " .AND. alltrim(U53_SATIV1) == '"+alltrim(cAtivid)+"'"
	cCondicao += " .AND. alltrim(U53_GRUPO)  == '"+alltrim(cGrpProd)+"'"
	cCondicao += " .AND. alltrim(U53_CODPRO) == '"+alltrim(cProduto)+"'"

	// limpo os filtros da U53
	U53->(DbClearFilter())

	// executo o filtro na U53
	bCondicao 	:= "{|| " + cCondicao + " }"
	U53->(DbSetFilter(&bCondicao,cCondicao))

	// vou para a primeira linha
	U53->(DbGoTop())

	if U53->(!Eof())
		cTpRegra := U53->U53_TPRGNG
	endif

	// limpo os filtros da U53
	U53->(DbClearFilter())

	RestArea(aArea)
Return cTpRegra

/*/{Protheus.doc} TRET022E
Analisa se a rotina Cliente x Veículos x Motorista será chamada em modo de inclusão ou alteração - origem Cadastro de Cliente
@author TOTVS
@since 25/11/2014
@version P11
@param Nao recebe parametros
@return nulo
/*/
User Function TRET022E(cCli,cLojaCli)
	Local aArea			:= GetArea()
	Local lEditaU44		:= .T.

	Private inclui		:= .F.
	Private altera		:= .F.

	Public __cCli		:= cCli
	Public __cLojaCli 	:= cLojaCli

//cadastra rotina para controle de acesso
	U_TRETA37B("U44UPD", "INCLUI/ALTERA NEGOCIACAO DE PAGAMENTO")
//verifica se o usuário tem permissão para acesso a rotina
	lEditaU44 := U_VLACESS2("U44UPD", RetCodUsr())

	dbselectarea("U52")
	U52->(dbsetorder(1)) //U52_FILIAL+U52_CODCLI+U52_LOJA+U52_GRPVEN+U52_CLASSE+U52_SATIV1
	If U52->(dbseek(xFilial("U52")+cCli+cLojaCli))
		if lEditaU44
			inclui		:= .F.
			altera		:= .T.
			FWExecView('ALTERAR','TRETA022',4,,{|| .T. /*fecha janela no ok*/ }) //Alteração
		else
			inclui		:= .F.
			altera		:= .F.
			FWExecView('VISUALIZA','TRETA022',1,,{|| .T. /*fecha janela no ok*/ }) //Alteração
		endif
	Else
		if lEditaU44
			inclui		:= .T.
			altera		:= .F.
			FWExecView('INCLUIR','TRETA022',3,,{|| .T. /*fecha janela no ok*/ }) //Inclusão
		else
			Help(,,"Atenção",,"Não há negociação de pagamento para este cliente.",1,0,,,,,,{""})
		endif
	Endif

//crio como private pois o sistema irá sobrescrever as variaveis Public
	Private __cCli		:= ""
	Private __cLojaCli 	:= ""

	RestArea(aArea)
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} TRET022F
Função que replica a regra negociação de pagamento de uma filial para as
filiais selecionadas no GRID 
@author  Henrique
@since   02/04/2015
@version version
/*/
//-------------------------------------------------------------------
User Function TRET022F()
	Local btnCanc
	Local btnConf
	Local lblCliente
	Local lblFilial
	Local lblLoja
	Local oSay1
	Local txtCdCli
	Local cxtCdCli 		:= U52->U52_CODCLI
	Local txtCdFilial
	Local cxtCdFilial 	:= U52->U52_FILIAL
	Local txtCdGrpCli
	Local cxtCdGrpCli 	:= U52->U52_GRPVEN
	Local txtCdLoja
	Local cxtCdLoja 	:= U52->U52_LOJA
	Local txtNmCli
	Local cxtNmCli 		:= Posicione("SA1",1,xFilial("SA1")+cxtCdCli+cxtCdLoja,"A1_NOME")
	Local txtNmFil
	Local cxtNmFil 		:= FWFilialName()    //busca o nome da filial
//Static oDlg

//Local cQry			:= ""
	Local aInf			:= {}
	Local aCampos		:= {{"OK","C",002,0},{"COL1","C",TamSX3("A1_FILIAL")[1],0},{"COL2","C",040,0},{"COL3","C",040,0}}
	Local aCampos2		:= {{"OK","","",""},{"COL1","","Código",""},{"COL2","","Filial",""},{"COL3","","Nome",""}}
	Local nPosIt		:= 0
	Local _cSep
	Local _cInf
	Local nI
	
	Private oSay2, oSay3
	Private aDados		:= {}
	Private cRet		:= ""
	Private oTempTable as object

	Private oDlg
	Private oMark
	Private cMarca	 	:= "mk"
	Private lImpFechar	:= .F.

	Private nContSel	:= 0
//Private QRYAUX
	Private TRBAUX
	Private cInf := _cInf
	Private FilGRID := "" //filial no grid

	Default _cSep		:= "/" //separador de retorno
	aInf				:= IIF(!Empty(_cInf),StrTokArr(AllTrim(StrTran(_cInf,CRLF,"")),_cSep),{})

	DbSelectArea("SM0")
	nRec := SM0->(Recno())
	SM0->(dbGoTop())
	While SM0->(!Eof())
		if (SM0->M0_CODFIL != cxtCdFilial)
			if (SM0->M0_CODIGO == cEmpAnt)
				//if (SM0->D_E_L_E_T_<> '*')
					aAdd(aDados,{&("SM0->M0_CODFIL"),&("SM0->M0_FILIAL"),&("SM0->M0_NOME"),""})
				//endif
			endif
		endif
		SM0->(DbSkip())
	End Do
//libero registro
//SM0->(dbCloseArea()) COMENTEI ESSA LINHA POIS NÃO PODE FECHAR ESSA TABELA DE FILIAIS
	SM0->(dbGoTo(nRec))

	//cria a tabela temporaria
	oTempTable := FWTemporaryTable():New("TRBAUX")
	oTempTable:SetFields(aCampos)
	oTempTable:Create()

	DbSelectArea("TRBAUX")

	If Len(aDados) > 0
		For nI := 1 to Len(aDados)
			TRBAUX->(RecLock("TRBAUX",.T.))
			If Len(aInf) > 0
				nPosIt := aScan(aInf,{|x| AllTrim(x) == AllTrim(aDados[nI][1])})
				If nPosIt > 0
					TRBAUX->OK := "mk"
					nContSel++
				Else
					TRBAUX->OK := "  "
				Endif
			Else
				TRBAUX->OK := "  "
			Endif

			TRBAUX->COL1 := aDados[nI][1]  //CODIGO
			TRBAUX->COL2 := aDados[nI][2]  //FILIAL
			TRBAUX->COL3 := aDados[nI][3]  //NOME
			TRBAUX->(MsUnlock())

		Next
	Else
		TRBAUX->(RecLock("TRBAUX",.T.))
		TRBAUX->OK		:= "  "
		TRBAUX->COL1	:= Space(TamSX3("A1_FILIAL")[1])	//CODIGO
		TRBAUX->COL2 	:= Space(040)						//FILIAL
		TRBAUX->COL3 	:= Space(040)						//NOME
		TRBAUX->(MsUnlock())
	Endif

	TRBAUX->(DbGoTop())   //POSICIONA O GRID NA PRIMEIRA LINHA


	DEFINE MSDIALOG oDlg TITLE "Replicação de Regra de Negociação de Pagamento Cliente" FROM 000, 000  TO 500, 750 COLORS 0, 16777215 PIXEL

	@ 012, 008 SAY lblFilial 	PROMPT "Filial:" 		SIZE 015, 009 OF oDlg COLORS 0, 16777215 PIXEL
	@ 012, 142 SAY lblCliente 	PROMPT "Cliente:" 		SIZE 020, 009 OF oDlg COLORS 0, 16777215 PIXEL
	@ 012, 262 SAY lblLoja 		PROMPT "Loja:" 			SIZE 014, 009 OF oDlg COLORS 0, 16777215 PIXEL
	@ 012, 306 SAY oSay1 		PROMPT "Grp. Clientes:" SIZE 033, 009 OF oDlg COLORS 0, 16777215 PIXEL
	@ 009, 021 MSGET txtCdFilial 	VAR cxtCdFilial SIZE 025, 010 WHEN .F. OF oDlg COLORS 0, 16777215 PIXEL
	@ 009, 162 MSGET txtCdCli 		VAR cxtCdCli 	SIZE 025, 010 WHEN .F. OF oDlg COLORS 0, 16777215 PIXEL
	@ 009, 274 MSGET txtCdLoja 		VAR cxtCdLoja 	SIZE 025, 010 WHEN .F. OF oDlg COLORS 0, 16777215 PIXEL
	@ 009, 045 MSGET txtNmFil 		VAR cxtNmFil 	SIZE 087, 010 WHEN .F. OF oDlg COLORS 0, 16777215 PIXEL
	@ 009, 186 MSGET txtNmCli 		VAR cxtNmCli 	SIZE 067, 010 WHEN .F. OF oDlg COLORS 0, 16777215 PIXEL
	@ 009, 339 MSGET txtCdGrpCli 	VAR cxtCdGrpCli SIZE 025, 010 WHEN .F. OF oDlg COLORS 0, 16777215 PIXEL

	//Browse  -  GRID
	oMark := MsSelect():New("TRBAUX","OK","",aCampos2,,@cMarca,{030,005,220,370})
	oMark:bMark 				:= {||MarcaIt()}
	oMark:oBrowse:LCANALLMARK 	:= .T.
	oMark:oBrowse:LHASMARK    	:= .T.
	oMark:oBrowse:bAllMark 		:= {||MarcaT()}

	@ 235, 005 SAY oSay2 PROMPT "Total de registros selecionados:" SIZE 200, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 235, 090 SAY oSay3 PROMPT cValToChar(nContSel) SIZE 040, 007 OF oDlg COLORS 0, 16777215 PIXEL

	@ 230, 280 BUTTON btnConf PROMPT "Confirmar" SIZE 039, 013 OF oDlg ACTION MsAguarde({|| ConfRepli()}, "Aguarde","Replicando informações...",.F.) PIXEL
	@ 230, 330 BUTTON btnCanc PROMPT "Cancelar" SIZE 039, 013 OF oDlg ACTION Fech001() PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED VALID lImpFechar //impede o usuario fechar a janela atraves do [X]

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} Fech001
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function Fech001()

	lImpFechar := .T.

	If Select("TRBAUX") > 0   //TRBAUX
		TRBAUX->(DbCloseArea())
	Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Apagando arquivo temporario                                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oTempTable:Delete()

	oDlg:End()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MarcaIt
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MarcaIt()

	If TRBAUX->OK == "mk"
		nContSel++
	Else
		--nContSel
	Endif

	oSay3:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MarcaT
description
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MarcaT()

	Local lMarca 	:= .F.
	Local lNMARCA 	:= .F.

	nContSel := 0

	TRBAUX->(dbGoTop())

	While TRBAUX->(!EOF())
		If TRBAUX->OK == "mk" .And. !lMarca
			RecLock("TRBAUX",.F.)
			TRBAUX->OK := "  "
			TRBAUX->(MsUnlock())
			lNMarca := .T.
		Else
			If !lNMarca
				RecLock("TRBAUX",.F.)
				TRBAUX->OK := "mk"
				TRBAUX->(MsUnlock())
				nContSel++
				lMarca := .T.
			Endif
		Endif

		TRBAUX->(dbSkip())
	EndDo

	TRBAUX->(dbGoTop())

	oSay3:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} ConfRepli
Função que é chamada ao clicar no botão "Replicar" na função Replica().
Esta função Replica as informacoes de forma de pagamento de uma
filial pre-selecionada  para uma ou mais filiais selecionadas
pelo cliente
@author  Henrique Botelho Gomes
@since   02/04/2015 
@version version
/*/
//-------------------------------------------------------------------
Static Function ConfRepli()

	Local aAuxClient  := {}  //Array auxiliar que guarda os dados do cliente principal selecionado
	Local aAuxFilhos  := {}
	Local contErro 	  := 0
	Local nX

//SALVA EM UM ARRAY OS DADOS DA FILIAL PAI (CABEÇALHO) SELECIONADA A SER REPLICADO PARA OUTRAS FILIAIS
	AAdd(aAuxClient,U52->U52_FILIAL)
	AAdd(aAuxClient,U52->U52_CODCLI)
	AAdd(aAuxClient,U52->U52_LOJA)
	AAdd(aAuxClient,U52->U52_GRPVEN)
	AAdd(aAuxClient,U52->U52_CLASSE)
	AAdd(aAuxClient,U52->U52_SATIV1)

	U53->(dbSetOrder(1)) //U53_FILIAL+U53_CODCLI+U53_LOJA+U53_GRPVEN+U53_CLASSE+U53_SATIV1+U53_ITEM
	U53->(dbGoTop())
	If U53->(dbSeek(xFilial("U53") + U52->U52_CODCLI + U52->U52_LOJA + U52->U52_GRPVEN + U52->U52_CLASSE + U52->U52_SATIV1))     // Busca exata, se verdadeiro, entra
		While U53->(!Eof()) .and. U53->(U53_FILIAL+U53_CODCLI+U53_LOJA+U53_GRPVEN+U53_CLASSE+U53_SATIV1) == (xFilial("U53") + U52->U52_CODCLI + U52->U52_LOJA + U52->U52_GRPVEN + U52->U52_CLASSE + U52->U52_SATIV1)
			aAuxFilho := {}
			Aadd(aAuxFilho,U53->U53_ITEM)
			Aadd(aAuxFilho,U53->U53_FORMPG)
			Aadd(aAuxFilho,U53->U53_DESCFP)
			Aadd(aAuxFilho,U53->U53_CONDPG)
			Aadd(aAuxFilho,U53->U53_DESCPG)
			Aadd(aAuxFilho,U53->U53_TPRGNG)
			Aadd(aAuxFilho,U53->U53_CODPRO)
			Aadd(aAuxFilho,U53->U53_DESCPR)
			Aadd(aAuxFilho,U53->U53_GRUPO)
			Aadd(aAuxFilho,U53->U53_DESCGR)
			Aadd(aAuxFilho,U53->U53_DESCRI)
			Aadd(aAuxFilhos,aAuxFilho)
			U53->(DbSkip())
		EndDo
	EndIf

	TRBAUX->(dbGoTop())

	While TRBAUX->(!EOF())

		If TRBAUX->OK == "mk"   //Se linha da grid selecionada

			// inicio o controle de transação para inclusão
			BeginTran()

			//atualiza no registro posicionado o segundo browser as informações do cliente selecionado no primeiro browser
			U52->(dbSetOrder(1))

			If !U52->(dbSeek(TRBAUX->COL1 + aAuxClient[2] + aAuxClient[3] + aAuxClient[4] + aAuxClient[5] + aAuxClient[6]))     // Busca exata, se verdadeiro, entra
				RECLOCK("U52", .T.)  //F-> altera.  T-> inclui

				//Mantem somente o número da filial selecionada como pai, e inclui os outros dados
				U52->U52_FILIAL := TRBAUX->COL1
				U52->U52_CODCLI := aAuxClient[2]
				U52->U52_LOJA 	:= aAuxClient[3]
				U52->U52_GRPVEN := aAuxClient[4]
				U52->U52_CLASSE := aAuxClient[5]
				U52->U52_SATIV1 := aAuxClient[6]

				U52->(MSUNLOCK())     // Destrava o registro

				//Função que grava o flag para integração das bases POSTO X RETAGUARDA
				U_UREPLICA("U52",1,TRBAUX->COL1 + aAuxClient[2] + aAuxClient[3] + aAuxClient[4] + aAuxClient[5] + aAuxClient[6],"I")

			Else //se não foi localizado o registro, então gera erro
				contErro++
			Endif

			//inclui os filhos
			For nX:=1 to Len(aAuxFilhos)
				If !U53->(dbSeek(TRBAUX->COL1 + aAuxClient[2] + aAuxClient[3] + aAuxClient[4] + aAuxClient[5] + aAuxClient[6] + aAuxFilhos[nX][1]))     // Busca exata, se verdadeiro, entra
					RecLock("U53",.T.)
					U53->U53_FILIAL := TRBAUX->COL1
					U53->U53_ITEM	:= aAuxFilhos[nX][1]
					U53->U53_FORMPG	:= aAuxFilhos[nX][2]
					U53->U53_DESCFP	:= aAuxFilhos[nX][3]
					U53->U53_CONDPG	:= aAuxFilhos[nX][4]
					U53->U53_DESCPG	:= aAuxFilhos[nX][5]
					U53->U53_TPRGNG	:= aAuxFilhos[nX][6]
					U53->U53_CODPRO	:= aAuxFilhos[nX][7]
					U53->U53_DESCPR	:= aAuxFilhos[nX][8]
					U53->U53_GRUPO	:= aAuxFilhos[nX][9]
					U53->U53_DESCGR	:= aAuxFilhos[nX][10]
					U53->U53_DESCRI	:= aAuxFilhos[nX][11]
					U53->U53_CODCLI	:= aAuxClient[2]
					U53->U53_LOJA	:= aAuxClient[3]
					U53->U53_GRPVEN	:= aAuxClient[4]
					U53->U53_CLASSE	:= aAuxClient[5]
					U53->U53_SATIV1	:= aAuxClient[6]
					U53->(MsUnlock())

					//Função que grava o flag para integração das bases POSTO X RETAGUARDA
					U_UREPLICA("U53",1,TRBAUX->COL1 + aAuxClient[2] + aAuxClient[3] + aAuxClient[4] + aAuxClient[5] + aAuxClient[6] + aAuxFilhos[nX][1],"I")
				Else
					contErro++
				EndIf
			Next nX

			//Emite mensagem de erro ou não
			If(contErro > 0)

				Help(,,"Atenção",,"Não foi possível replicar as informações para a empresa "+AllTrim(TRBAUX->COL2)+".",1,0,,,,,,{""})

				// cancelo a transação de inclusão
				DisarmTransaction()

				// Libera sequencial
				RollBackSx8()
			Else

				// Confirmo a numeração
				ConfirmSX8()
			Endif

			// finalizo o controle de transação para inclusão
		EndTran()

	EndIf

	contErro := 0
	TRBAUX->(dbSkip()) //AVANÇA UM REGISTRO

EndDo  // End of While TRBAUX->(!EOF())

Help(,,"Atenção",,"Informações processadas!.",1,0,,,,,,{""})

Fech001()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} TRET022G
 Gera lista de negociações de preço com problema
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRET022G()
	Local cListCamp	:= ""
	Static oDlgDet

	MsAguarde( {|| CarrDados(@cListCamp)}, "Aguarde", "Selecionando registros...", .F. )

	If !Empty(cListCamp)

		cFileLog := MemoWrite( GetNextAlias() + ".log", cListCamp )
		Define Font oFont Name "Arial" Size 5, 14
		Define MsDialog oDlgDet Title "Lista Gerada" From 3, 0 to 340, 417 Pixel

		@ 5, 5 Get oMemo Var cListCamp Memo Size 200, 145 Of oDlgDet Pixel
		oMemo:bRClicked := { || AllwaysTrue() }
		oMemo:oFont     := oFont

		Define SButton From 153, 175 Type  1 Action oDlgDet:End() Enable Of oDlgDet Pixel // Apaga
		Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
			MemoWrite( cFile, cListCamp ) ) ) Enable Of oDlgDet Pixel

		Activate MsDialog oDlgDet Center

	Else
		Aviso( "Atenção!", "Não existe preço negociado com problemas a serem listados.", {"Ok"} )
	EndIf

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} CarrDados
carrega os problemas com os preços negociados
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function CarrDados(cListCamp)
	Local cHelp := ""
	Local cSequ := "000000"
	Local aArea := GetArea()
	Local aAreaU25 := U25->(GetArea())
	Local lRet := .T.

	DbSelectArea("U25")
	U25->(DbSetOrder(2)) //U25_FILIAL+U25_PRODUT+U25_CLIENT+U25_LOJA+U25_FORPAG+U25_CONDPG+U25_ADMFIN+DTOS(U25_DTINIC)+U25_HRINIC
	U25->(DbGoTop()) //posiciono no ultimo preço, caso exista mais de um
	While U25->(!Eof())

		//pega somente as negociações ativas
		If (DTOS(U25->U25_DTINIC) <= DTOS(ddatabase)) .AND. ;
				((DTOS(U25->U25_DTFIM) == DTOS(CTOD("")) .AND. Empty(U25->U25_HRFIM)) .OR. (DTOS(U25->U25_DTFIM)+U25->U25_HRFIM >= DTOS(ddatabase)+SUBSTR(Time(),1,5))) .AND. ;
				!Empty(U25->U25_FORPAG) .AND. !Empty(U25->U25_CONDPG) .AND. !Empty(U25->U25_CLIENT) .AND. !Empty(U25->U25_LOJA) .AND. !Empty(U25->U25_PRODUT) .AND. U25->U25_BLQL <> 'S'


			cFormPg 	:= U25->U25_FORPAG
			cCondPg 	:= U25->U25_CONDPG
			cCodCli		:= U25->U25_CLIENT
			cLojCli		:= U25->U25_LOJA
			cProduto	:= U25->U25_PRODUT
			lHelp		:= .F.
			cHelp 		:= ""

			lRet := U_TRET022D(cFormPg,cCondPg,cCodCli,cLojCli,cProduto,lHelp,@cHelp)
			If !lRet

				cSequ := SOMA1(cSequ)

				cListCamp += cSequ + CRLF +;
					"Chave:"+ CRLF +;
					"<U25_FILIAL+U25_PRODUT+U25_CLIENT+U25_LOJA+U25_FORPAG+U25_CONDPG+U25_ADMFIN+DTOS(U25_DTINIC)+U25_HRINIC>"+ CRLF +;
					U25->(U25_FILIAL+U25_PRODUT+U25_CLIENT+U25_LOJA+U25_FORPAG+U25_CONDPG+U25_ADMFIN+DTOS(U25_DTINIC)+U25_HRINIC)+ CRLF +;
					"Erro: "+ CRLF +;
					cHelp+ CRLF + CRLF

			EndIf

		EndIf
		U25->(DbSkip())
	EndDo

	RestArea(aAreaU25)
	RestArea(aArea)
Return

	Static a022Fil := {} //para guardar as filiais
//-------------------------------------------------------------------
/*/{Protheus.doc} TRET022R
Tela para replicar Regra de Negociação
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
User Function TRET022R

	Local nRecSM0, nPosAux
	Local aSize 	:= MsAdvSize() // Retorna a área útil das janelas Protheus
	Local aInfo 	:= {aSize[1], aSize[2], aSize[3], aSize[4], 2, 2}
	Local aObjects 	:= {{100,30,.T.,.T.},{100,70,.T.,.T.}}
	Local aPObj 	:= MsObjSize( aInfo, aObjects, .T. )
	Local aHeaderEx
	Local bMarcaTodos := {|x| iif(lMARKALL, x[1]:="LBNO", x[1]:="LBOK") }
	Local cQry := ""
	Private lMARKALL := .F.
	Private nMARKALL := 0
	Private oDlgRepl
	Private aCpU53 := {"U53_FORMPG", "U53_CONDPG", "U53_DESCRI","U53_CODPRO","U53_DESCPR","U53_GRUPO","U53_DESCGR"}
	Private aCpSM0 := {"MARK","U53_FILIAL","U53_DESCFP"}
	Private aDadosU53 := {}
	Private oGridU53
	Private oGridSM0
	Private cCadastro := "Replicar Regra de Negociação entre Filiais"

	if empty(a022Fil)
		DbSelectArea("SM0")
		nRecSM0 := SM0->(Recno())
		SM0->(dbGoTop())
		While SM0->(!Eof())
			if (SM0->M0_CODIGO == cEmpAnt)
				//if (SM0->D_E_L_E_T_<>'*')
					aAdd(a022Fil,{"LBNO",Alltrim(SM0->M0_CODFIL),Alltrim(SM0->M0_FILIAL), .F.})
				//endif
			endif
			SM0->(DbSkip())
		EndDo
		SM0->(dbGoTo(nRecSM0))
	endif

	cQry := "SELECT U53.* "
	cQry += "FROM "+RetSqlName("U53")+" U53 "
	cQry += "WHERE U53.D_E_L_E_T_ = ' ' "
	cQry += "AND U53_CODCLI = '"+U52->U52_CODCLI+"' "
	cQry += "AND U53_LOJA = '"+U52->U52_LOJA+"' "
	cQry += "AND U53_GRPVEN = '"+U52->U52_GRPVEN+"' "
	cQry += "AND U53_CLASSE = '"+U52->U52_CLASSE+"' "
	cQry += "AND U53_SATIV1 = '"+U52->U52_SATIV1+"' "
	cQry += "ORDER BY U53_FORMPG, U53_CONDPG, U53_CODPRO, U53_GRUPO, U53_FILIAL "

	if Select("QRYT1") > 0
		QRYT1->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

	While QRYT1->(!Eof())

		nPosAux := aScan(aDadosU53, {|x| x[1]+x[2]+x[4]+x[6] == QRYT1->U53_FORMPG+QRYT1->U53_CONDPG+QRYT1->U53_CODPRO+QRYT1->U53_GRUPO })

		if nPosAux == 0
			aadd(aDadosU53, {;
				QRYT1->U53_FORMPG,;
				QRYT1->U53_CONDPG,;
				QRYT1->U53_DESCRI,;
				QRYT1->U53_CODPRO,;
				QRYT1->U53_DESCPR,;
				QRYT1->U53_GRUPO,;
				QRYT1->U53_DESCGR,;
				{QRYT1->U53_FILIAL},; //array de filiais
			.F.;//deletado
			})
		else
			if aScan(aDadosU53[nPosAux][len(aCpU53)+1], QRYT1->U53_FILIAL) == 0
				aadd(aDadosU53[nPosAux][len(aCpU53)+1], QRYT1->U53_FILIAL )
			endif
		endif

		QRYT1->(DbSkip())
	EndDo

	QRYT1->(DbCloseArea())

	if empty(aDadosU53)
		MsgInfo("Não há regras de negociação para esse cliente/grupo.","Atenção")
		Return
	endif

	DEFINE MSDIALOG oDlgRepl TITLE "Replicar Regra de Negociação entre filiais" FROM aSize[7],aSize[1] TO aSize[6],aSize[5] PIXEL

	EnchoiceBar(oDlgRepl, {|| MsAguarde({|| GrvMultiFil() }, "Aguarde","Replicando informações...",.F.), oDlgRepl:End() },{|| oDlgRepl:End()},, {})
	EnChoice( "U52",U52->(Recno()),2,,,,,aPObj[1],,,,,,oDlgRepl)

	@ aPObj[2,1]+5, aPObj[2,2] SAY "Regras de Negociação" SIZE 200, 007 OF oDlgRepl COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCpU53, .F.)
	oGridU53 := MsNewGetDados():New( aPObj[2,1]+15, aPObj[2,2], aPObj[2,3], aPObj[2,4]-200,,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oDlgRepl, aHeaderEx, {})
	oGridU53:aCols := aDadosU53 //seto mesmo array de memória
	oGridU53:oBrowse:bchange := {|| AtuGdFiliais(1) }

	@ aPObj[2,1]+5, aPObj[2,4]-195 SAY "Vigente nas Filiais" SIZE 200, 007 OF oDlgRepl COLORS 0, 16777215 PIXEL

	aHeaderEx := MontaHeader(aCpSM0, .F.)
	oGridSM0 := MsNewGetDados():New( aPObj[2,1]+15, aPObj[2,4]-195, aPObj[2,3], aPObj[2,4],,"AllwaysTrue","AllwaysTrue","+Field1+Field2",{},,999,"AllwaysTrue","AllwaysTrue","AllwaysTrue",oDlgRepl, aHeaderEx, a022Fil)
	oGridSM0:oBrowse:bLDblClick := {|| oGridSM0:aCols[oGridSM0:nAt][1] := iif(oGridSM0:aCols[oGridSM0:nAt][1]=="LBNO", iif(!empty(oGridSM0:aCols[oGridSM0:nAt][2]),"LBOK","LBNO"), "LBNO") , oGridSM0:oBrowse:Refresh(), AtuGdFiliais(2) }
	oGridSM0:oBrowse:bHeaderClick := {|oBrw,nCol| iif(nCol == 1 .AND. nMARKALL==1, (aEval(oGridSM0:aCols, bMarcaTodos),oBrw:Refresh(),oBrw:SetFocus(),lMARKALL:=!lMARKALL, AtuGdFiliais(2), nMARKALL:=0) , nMARKALL++ ) }

	//oDlgRepl:bInit := {||  }
	oDlgRepl:lCentered := .T.
	oDlgRepl:Activate()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} AtuGdFiliais
atualiza grid de filiais
//nTipo: 1=Joga do aFilUse para Grid
//		 2=Joga do Grid para aFilUse
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function AtuGdFiliais(nTipo)

	Local nX := 0
	Local aFilUse := aDadosU53[oGridU53:nAt][len(aCpU53)+1]

	if nTipo == 1
		for nX := 1 to len(oGridSM0:aCols)

			if aScan(aFilUse, oGridSM0:aCols[nX][2] ) > 0
				oGridSM0:aCols[nX][1] := "LBOK"
			else
				oGridSM0:aCols[nX][1] := "LBNO"
			endif

		next nX
	ElseIf nTipo == 2
		aSize(aFilUse, 0)
		for nX := 1 to len(oGridSM0:aCols)
			if oGridSM0:aCols[nX][1] == "LBOK"
				aadd(aFilUse, oGridSM0:aCols[nX][2])
			endif
		next nX

		if empty(aFilUse)
			aDadosU53[oGridU53:nAt][len(aCpU53)+2] := .T.
		else
			aDadosU53[oGridU53:nAt][len(aCpU53)+2] := .F.
		endif
	endif

	oGridSM0:oBrowse:Refresh()
	oGridU53:oBrowse:Refresh()

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} MontaHeader
Monta aHeader de acordo com campos passados
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function MontaHeader(aCampos, lRecno)

	Local aAuxLeg := {}
	Local aHeadRet := {}
	Local nX := 0
	Default lRecno := .T.

	For nX := 1 to Len(aCampos)
		If !("LEG_" $ aCampos[nX]) .AND. SubStr(aCampos[nX],1,3) == "LEG"
			aAuxLeg := StrToKArr(aCampos[nX],"-")
			if len(aAuxLeg) = 1
				aadd(aAuxLeg, ' ')
			endif
			Aadd(aHeadRet,{aAuxLeg[2],aAuxLeg[1],'@BMP',5,0,'','€€€€€€€€€€€€€€','C','','','',''})
		ElseIf aCampos[nX] == "MARK"
			Aadd(aHeadRet,{" ","MARK",'@BMP',3,0,'','€€€€€€€€€€€€€€','C','','','',''})
		ElseIf !Empty(GetSx3Cache(aCampos[nX],"X3_CAMPO")) //verifica se o campo existe na SX3
			Aadd(aHeadRet,U_UAHEADER(aCampos[nX]))
		EndIf
	Next nX

	if lRecno
		Aadd(aHeadRet, {"RecNo", "RECNO", "9999999999", 10, 0, "", "€€€€€€€€€€€€€€", "N", "","V", "", ""})
	endif

Return aHeadRet

//-------------------------------------------------------------------
/*/{Protheus.doc} GrvMultiFil
Gravação dos dados multi filial.
@author  author
@since   date
@version version
/*/
//-------------------------------------------------------------------
Static Function GrvMultiFil()

	Local nX, nY, nZ
	Local cChvU53, cFieldName, uValue
	Local aU53 := {}
	Local aAreaU52 := U52->(GetArea())
	Local cBkpFil := cFilAnt

	// inicio o controle de transação
	BeginTran()

	for nX := 1 to len(aDadosU53)

		RestArea(aAreaU52) //volto para a U52 original

		//BUSCANDO TODOS AS U53 COM MESMA CHAVE
		cQry := "SELECT U53_FILIAL, R_E_C_N_O_ RECU53 "
		cQry += "FROM "+RetSqlName("U53")+" "
		cQry += "WHERE D_E_L_E_T_ = ' ' "
		cQry += "AND U53_CODCLI = '"+U52->U52_CODCLI+"' "
		cQry += "AND U53_LOJA = '"+U52->U52_LOJA+"' "
		cQry += "AND U53_GRPVEN = '"+U52->U52_GRPVEN+"' "
		cQry += "AND U53_CLASSE = '"+U52->U52_CLASSE+"' "
		cQry += "AND U53_SATIV1 = '"+U52->U52_SATIV1+"' "
		cQry += "AND U53_FORMPG = '"+aDadosU53[nX][1] +"' "
		cQry += "AND U53_CONDPG = '"+aDadosU53[nX][2] +"' "
		cQry += "AND U53_CODPRO = '"+aDadosU53[nX][4] +"' "
		cQry += "AND U53_GRUPO = '"+aDadosU53[nX][6] +"' "
		cQry += "ORDER BY U53_FILIAL "

		if Select("QRYT1") > 0
			QRYT1->(DbCloseArea())
		Endif
		cQry := ChangeQuery(cQry)
		TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

		if aDadosU53[nX][len(aCpU53)+2] //se deletado, excluir todos encontrados da query (de todas as filiais)
			QRYT1->(DbGoTop())
			While QRYT1->(!Eof())
				U53->(DbGoTo(QRYT1->RECU53))
				cChvU53 := U53->U53_FILIAL+U53->U53_CODCLI+U53->U53_LOJA+U53->U53_GRPVEN+U53->U53_CLASSE+U53->U53_SATIV1+U53->U53_ITEM

				Reclock("U53",.F.)
				U53->(DbDelete())
				U53->(MsUnlock())
				U_UREPLICA("U53", 1, cChvU53, "E")

				//verificar se existe preço negociado e encerra-los
				cFilAnt := QRYT1->U53_FILIAL
				FWMsgRun(, {|oSay| U_TRET023K(@oSay,"",U52->U52_CODCLI, U52->U52_LOJA, U52->U52_GRPVEN, aDadosU53[nX][1], aDadosU53[nX][2])  }, "Aguarde! Processando...", "Ajuste dos Preços Negociados..." )
				cFilAnt := cBkpFil

				QRYT1->(DbSkip())
			EndDo
		else

			U52->(dbSetOrder(1))
			U53->(DbSetOrder(1))

			//percorrendo as filiais possíveis
			for nY := 1 to len(oGridSM0:aCols)

				if aScan(aDadosU53[nX][len(aCpU53)+1], oGridSM0:aCols[nY][2] ) > 0 //é para ter nessa filial

					//verifico se ja existe
					lJaExisteU53 := .F.
					QRYT1->(DbGoTop())
					While QRYT1->(!Eof())
						if QRYT1->U53_FILIAL == xFilial("U53", oGridSM0:aCols[nY][2])
							lJaExisteU53 := .T.
							EXIT
						endif
						QRYT1->(DbSkip())
					EndDo

					if !lJaExisteU53 //se nao existe ainda, inclui

						aU53 := {}

						//copiando dados
						QRYT1->(DbGoTop()) //vou para primeiro registro da chave
						U53->(DbGoTo(QRYT1->RECU53))
						For nZ := 1 To U53->(FCount())

							cFieldName := U53->(FieldName(nZ))

							if cFieldName == "U53_FILIAL"
								uValue := xFilial("U53", oGridSM0:aCols[nY][2])
							ElseIf cFieldName == "U53_ITEM"
								uValue := U53->(FieldGet(nZ))
								//verifico se sequencia ja está em uso e somo 1 até ficar disponivel
								cChvU53 := xFilial("U53", oGridSM0:aCols[nY][2])+U53->U53_CODCLI+U53->U53_LOJA+U53->U53_GRPVEN+U53->U53_CLASSE+U53->U53_SATIV1
								While U53->(DbSeek(cChvU53+uValue))
									uValue := soma1(uValue)
								enddo
								U53->(DbGoTo(QRYT1->RECU53)) //volto para o U53 corrente
							else
								uValue := U53->(FieldGet(nZ))
							endif

							AAdd( aU53 , { cFieldName, uValue } )

						Next nZ

						//gravando na filial corrente
						Reclock("U53", .T.) //inclusao
						for nZ := 1 to len(aU53)
							U53->&(aU53[nZ][1]) := aU53[nZ][2]
						next nZ
						U53->(MsUnlock())
						//Função que grava o flag para integração das bases POSTO X RETAGUARDA
						U_UREPLICA("U53",1, U53->U53_FILIAL+U53->U53_CODCLI+U53->U53_LOJA+U53->U53_GRPVEN+U53->U53_CLASSE+U53->U53_SATIV1+U53->U53_ITEM, "I")

						//verifico se existe a U52 dessa filial
						If !U52->(dbSeek( xFilial("U53", oGridSM0:aCols[nY][2])+U53->U53_CODCLI+U53->U53_LOJA+U53->U53_GRPVEN+U53->U53_CLASSE+U53->U53_SATIV1 ))
							Reclock("U52", .T.)
							U52->U52_FILIAL := xFilial("U53", oGridSM0:aCols[nY][2])
							U52->U52_CODCLI := U53->U53_CODCLI
							U52->U52_LOJA 	:= U53->U53_LOJA
							U52->U52_GRPVEN := U53->U53_GRPVEN
							U52->U52_CLASSE := U53->U53_CLASSE
							U52->U52_SATIV1 := U53->U53_SATIV1
							U52->(MsUnlock())

							//Função que grava o flag para integração das bases POSTO X RETAGUARDA
							U_UREPLICA("U52",1,U52->U52_FILIAL + U52->U52_CODCLI + U52->U52_LOJA + U52->U52_GRPVEN + U52->U52_CLASSE + U52->U52_SATIV1,"I")
						Endif

					endif

				else //não é para ter nessa filial

					//excluindo caso tenha
					QRYT1->(DbGoTop())
					While QRYT1->(!Eof())
						if QRYT1->U53_FILIAL == xFilial("U53", oGridSM0:aCols[nY][2])

							U53->(DbGoTo(QRYT1->RECU53))
							cChvU53 := U53->U53_FILIAL+U53->U53_CODCLI+U53->U53_LOJA+U53->U53_GRPVEN+U53->U53_CLASSE+U53->U53_SATIV1+U53->U53_ITEM

							Reclock("U53",.F.)
							U53->(DbDelete())
							U53->(MsUnlock())
							U_UREPLICA("U53", 1, cChvU53, "E")

							//verificar se existe preço negociado e encerra-los
							cFilAnt := oGridSM0:aCols[nY][2]
							FWMsgRun(, {|oSay| U_TRET023K(@oSay,"",U52->U52_CODCLI, U52->U52_LOJA, U52->U52_GRPVEN, aDadosU53[nX][1], aDadosU53[nX][2])  }, "Aguarde! Processando...", "Ajuste dos Preços Negociados..." )
							cFilAnt := cBkpFil

						endif
						QRYT1->(DbSkip())
					EndDo

				endif

			next
		endif

		QRYT1->(DbCloseArea())

	next nX

	//excluindo a U52 quando não há mais filha U53
	cQry := "SELECT U52.R_E_C_N_O_ RECU52 "
	cQry += "FROM "+RetSqlName("U52")+" U52 "
	cQry += "WHERE U52.D_E_L_E_T_ = ' ' "
	cQry += "AND U52_CODCLI = '"+U52->U52_CODCLI+"' "
	cQry += "AND U52_LOJA = '"+U52->U52_LOJA+"' "
	cQry += "AND U52_GRPVEN = '"+U52->U52_GRPVEN+"' "
	cQry += "AND U52_CLASSE = '"+U52->U52_CLASSE+"' "
	cQry += "AND U52_SATIV1 = '"+U52->U52_SATIV1+"' "
	cQry += "AND NOT EXISTS ("
	cQry += "	SELECT U53_FILIAL "
	cQry += "	FROM "+RetSqlName("U53")+" U53"
	cQry += "	WHERE U53.D_E_L_E_T_ = ' ' "
	cQry += "	AND U53_FILIAL = U52_FILIAL "
	cQry += "	AND U53_CODCLI = U52_CODCLI "
	cQry += "	AND U53_LOJA = U52_LOJA "
	cQry += "	AND U53_GRPVEN = U52_GRPVEN "
	cQry += "	AND U53_CLASSE = U52_CLASSE "
	cQry += "	AND U53_SATIV1 = U52_SATIV1 "
	cQry += ")"

	if Select("QRYT1") > 0
		QRYT1->(DbCloseArea())
	Endif
	cQry := ChangeQuery(cQry)
	TcQuery cQry New Alias "QRYT1" // Cria uma nova area com o resultado do query

	//excluindo caso tenha
	QRYT1->(DbGoTop())
	While QRYT1->(!Eof())

		U52->(DbGoTo(QRYT1->RECU52))
		cChvU53 := U52->U52_FILIAL+U52->U52_CODCLI+U52->U52_LOJA+U52->U52_GRPVEN+U52->U52_CLASSE+U52->U52_SATIV1

		Reclock("U52",.F.)
		U52->(DbDelete())
		U52->(MsUnlock())
		U_UREPLICA("U52", 1, cChvU53, "E")

		QRYT1->(DbSkip())
	EndDo
	QRYT1->(DbCloseArea())

	// fim do controle de transação
EndTran()

RestArea(aAreaU52) //volto para a U52 original

Return

//Modo ediçao dos campos chave Forma+Condicao
Static Function WhenChave(oModelU53, cFieldName)
	
	Local lRet
	lRet := oModelU53:GetDataId() == 0

Return lRet
