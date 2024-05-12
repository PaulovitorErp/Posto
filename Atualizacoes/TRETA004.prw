#INCLUDE "PROTHEUS.CH"
#INCLUDE "topconn.ch"
#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'FWEditPanel.CH'

/*/{Protheus.doc} TRETA004
Cadastro Unificado do Posto e Model/View de Tanques

@type function
@version 1.0  
@author Rafael Brito
@since 01/07/2022
/*/
User Function TRETA004()

	LjMsgRun("Aguarde... carregando cadastros...",,{|| TRETA004() })

Return

Static Function TRETA004()

	Local aCoors 		:= FWGetDialogSize( oMainWnd )
	Local cTitulo		:= "Cadastro Unificado do Posto"
	Local oPanelUp
	Local oFWLayer
	Local oPanelLeft
	Local oPanelRight
	Local oBrowseTq
	Local oBrowseCn
	Local oBrowseUp
	Local oBrowseLeft
	Local oBrowseRight
	Local oTFolder
	Local oRelacMIC
	Local oRelacMIB
	Private oDlgPrinc

	DEFINE MSDIALOG oDlgPrinc Title cTitulo  From aCoors[1], aCoors[2] To aCoors[3], aCoors[4] Pixel STYLE nOr(WS_VISIBLE, WS_POPUP)

	aTFolder := { 'Tanques', 'Concentradora', 'Bombas X Bico X Lacre' }
  	oTFolder := TFolder():New(0, 0,aTFolder,,oDlgPrinc,,,,.T.,,aCoors[4]/2, aCoors[3]/2 )
	
	// Cria o conteiner onde serão colocados os browses
	oFWLayer := FWLayer():New()
	oFWLayer:Init( oTFolder:aDialogs[3], .F., .T. )

	////////////////////////// PAINEL SUPERIOR /////////////////////////////
	// Cria uma "linha" com 50% da tela
	oFWLayer:AddLine( 'UP', 50, .F. )

	// Na "linha" criada eu crio uma coluna com 100% da tamanho dela
	oFWLayer:AddCollumn( 'ALL', 100, .T., 'UP' )

	// Pego o objeto desse pedaço do container
	oPanelUp := oFWLayer:GetColPanel( 'ALL', 'UP' )

	////////////////////////// PAINEL INFERIOR /////////////////////////////
	// Cria uma "linha" com 50% da tela
	oFWLayer:AddLine( 'DOWN', 50, .F. )

	// Na "linha" criada eu crio uma coluna com 49% da tamanho dela
	oFWLayer:AddCollumn( 'LEFT' , 49, .T., 'DOWN' )

	// Na "linha" criada eu crio uma coluna com 2% da tamanho dela, apenas para criar uma coluna separadora
	oFWLayer:AddCollumn( 'CENTER_COLUN', 2, .T., 'DOWN' )

	// Na "linha" criada eu crio uma coluna com 49% da tamanho dela
	oFWLayer:AddCollumn( 'RIGHT', 49, .T., 'DOWN' )

	// Pego o objeto do pedaço esquerdo
	oPanelLeft := oFWLayer:GetColPanel( 'LEFT' , 'DOWN' )

	// Pego o objeto do pedaço direito
	oPanelRight := oFWLayer:GetColPanel( 'RIGHT', 'DOWN' )

	////////////////////// MONTO O BROWSER DE TANQUES ////////////////////////
	oBrowseTq := FWmBrowse():New()
	oBrowseTq :SetOwner( oTFolder:aDialogs[1] )

	// Atribuo o título do Browser
	oBrowseTq:SetDescription( "Tanques" )

	// Atribuo o nome da tabela
	oBrowseTq:SetAlias( 'MHZ' )

	// Habilito a visualização do Menu
	oBrowseTq:SetMenuDef( 'TRETA004' )

	// Desabilito o detalhamento do browser
	oBrowseTq:DisableDetails()

	oBrowseTq:SetProfileID( '1' )
	oBrowseTq:ForceQuitButton()

	//adiciona legenda no Browser
	oBrowseTq:AddLegend( "MHZ_STATUS == '1' .and. (Empty(MHZ_DTDESA) .or. MHZ_DTDESA >= Date())"	, "GREEN"	, "Ativado")
	oBrowseTq:AddLegend( "MHZ_STATUS == '2' .OR. MHZ_DTDESA < Date()"	, "RED" 	, "Desativado")

	oBrowseTq:Activate()

	////////////////////// MONTO O BROWSER DE CONCENTRADORAS ////////////////////////
	oBrowseCn := FWmBrowse():New()
	oBrowseCn :SetOwner( oTFolder:aDialogs[2] )

	// Atribuo o título do Browser
	oBrowseCn:SetDescription( "Concentradoras" )

	// Atribuo o nome da tabela
	oBrowseCn:SetAlias( 'MHX' )

	// Habilito a visualização do Menu
	oBrowseCn:SetMenuDef( 'TRETA011' )

	// Desabilito o detalhamento do browser
	oBrowseCn:DisableDetails()

	oBrowseCn:SetProfileID( '1' )
	oBrowseCn:ForceQuitButton()

	//adiciona legenda no Browser
	oBrowseCn:AddLegend( "MHX_STATUS == '1'", "GREEN", "Ativado")
	oBrowseCn:AddLegend( "MHX_STATUS == '2'", "RED"  , "Desativado")

	oBrowseCn:Activate()

	////////////////////// MONTO O BROWSER DE BOMBAS ////////////////////////
	oBrowseUp := FWMBrowse():New()
	oBrowseUp :SetOwner( oPanelUP )

	// Atribuo o título do Browser
	oBrowseUp :SetDescription( 'Bombas' )

	// Desabilito a visualização do Menu, pois o usuário não pode incluir um módulo individualmente
	oBrowseUp :SetMenuDef('TRETA051')

	// Desabilito o detalhamento do browser
	oBrowseUp:DisableDetails()

	// Atribuo o nome da tabela
	oBrowseUp:SetAlias( 'MHY' )

	oBrowseUp:SetProfileID( '1' )
	oBrowseTq:ForceQuitButton()

	oBrowseUp:AddLegend( "MHY_STATUS == '1'"	, "GREEN"	, "Ativado")
	oBrowseUp:AddLegend( "MHY_STATUS == '2'"	, "RED" 	, "Desativado")

	oBrowseUp:Activate()

	////////////////////// MONTO O BROWSER DE BICOS ////////////////////////
	oBrowseLeft:= FWMBrowse():New()
	oBrowseLeft:SetOwner( oPanelLeft )

	// Atribuo o título do Browser
	oBrowseLeft:SetDescription( 'BICOS' )

	// Desabilito a visualização do Menu, pois o usuário não pode incluir um jazigo individualmente
	oBrowseLeft:SetMenuDef( '' )

	// Desabilito o detalhamento do browser
	oBrowseLeft:DisableDetails()

	// Atribuo o nome da tabela
	oBrowseLeft:SetAlias( 'MIC' )

	oBrowseLeft:SetProfileID( '2' )

	// adiciona legenda no Browser
	oBrowseLeft:AddLegend( "MIC_STATUS == '1' .and. (Empty(MIC_XDTDES) .or. MIC_XDTDES >= Date())"	, "GREEN"	, "Ativado")
	oBrowseLeft:AddLegend( "MIC_STATUS == '2' .OR. MIC_XDTDES < Date()"	, "RED" 	, "Desativado")

	oBrowseLeft:Activate()


	////////////////////// MONTO O BROWSER DE LACRES ////////////////////////
	oBrowseRight:= FWMBrowse():New()
	oBrowseRight:SetOwner( oPanelRight )

	// Atribuo o título do Browser
	oBrowseRight:SetDescription( 'LACRES' )

	// Desabilito a visualização do Menu, pois o usuário não pode incluir um jazigo individualmente
	oBrowseRight:SetMenuDef( '' )

	// Desabilito o detalhamento do browser
	oBrowseRight:DisableDetails()

	// Atribuo o nome da tabela
	oBrowseRight:SetAlias( 'MIB' )

	oBrowseRight:SetProfileID( '3' )

	oBrowseRight:Activate()


	////////////////////// DEFINO O RELACIONAMENTO ENTRE OS BROWSER's ////////////////////////
	oRelacMIC:= FWBrwRelation():New()
	oRelacMIC:AddRelation( oBrowseUp , oBrowseLeft , { { 'MIC_FILIAL', 'MHY_FILIAL' }, { 'MIC_CODBOM' , 'MHY_CODBOM' } } )
	oRelacMIC:Activate()

	oRelacMIB:= FWBrwRelation():New()
	oRelacMIB:AddRelation( oBrowseUp, oBrowseRight, { { 'MIB_FILIAL', 'MHY_FILIAL' }, { 'MIB_CODBOM', 'MHY_CODBOM' }, { 'MIB_CODMAN', 'Space(6)' } } )
	oRelacMIB:Activate()

	Activate MsDialog oDlgPrinc Center

Return(Nil)

/*/{Protheus.doc} TRETA011
Cadastro de Tanques

@author Danilo
@since 13/07/2023
@version 1.0
@type function
/*/
User Function TRETA04A()

	Local oBrowse

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( 'MHZ' )
	oBrowse:SetDescription( 'Cadastro de Tanques' )

	//adiciona legenda no Browser
	oBrowse:AddLegend( "MHZ_STATUS == '1' .and. (Empty(MHZ_DTDESA) .or. MHZ_DTDESA >= Date())"	, "GREEN"	, "Ativado")
	oBrowse:AddLegend( "MHZ_STATUS == '2' .OR. MHZ_DTDESA < Date()"	, "RED" 	, "Desativado")

	oBrowse:Activate()

Return NIL


/*/{Protheus.doc} MenuDef
Cria os Menus da Rotina

@type function
@version 1.0  
@author Rafael Brito
@since 01/07/2022
/*/
Static Function MenuDef()

	Local aRotina 		:= {}

	ADD OPTION aRotina Title 'Pesquisar'   				Action 'PesqBrw'          	OPERATION 01 ACCESS 0
	ADD OPTION aRotina Title 'Visualizar'  				Action 'VIEWDEF.TRETA004' 	OPERATION 02 ACCESS 0
	ADD OPTION aRotina Title 'Incluir'     				Action 'VIEWDEF.TRETA004' 	OPERATION 03 ACCESS 0
	ADD OPTION aRotina Title 'Alterar'     				Action 'VIEWDEF.TRETA004' 	OPERATION 04 ACCESS 0
	ADD OPTION aRotina Title 'Excluir'     				Action 'VIEWDEF.TRETA004' 	OPERATION 05 ACCESS 0
	ADD OPTION aRotina Title 'Imprimir'    				Action 'VIEWDEF.TRETA004' 	OPERATION 08 ACCESS 0
	
Return(aRotina)

/*/{Protheus.doc} ModelDef
Cria o Modelo de Dados

@type function
@version 1.0  
@author Rafael Brito
@since 01/07/2022
/*/
Static Function ModelDef()

	Local oStruMHY := FWFormStruct( 1, 'MHZ', /*bAvalCampo*/, /*lViewUsado*/ )
	Local oModel

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New( 'TRETM004', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields( 'MHZMASTER', /*cOwner*/, oStruMHY )

	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Cadastro de Tanques' )

	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "MHZ_FILIAL" , "MHZ_CODTAN" })

	// Adiciona a descricao do Componente do Modelo de Dados
	oModel:GetModel( 'MHZMASTER' ):SetDescription( 'Dados do Tanque' )

Return(oModel)

/*/{Protheus.doc} ViewDef
Cria a camada de visão

@type function
@version 1.0  
@author Rafael Brito
@since 01/07/2022
/*/
Static Function ViewDef()

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oStruMHZ := FWFormStruct( 2, 'MHZ' )

	// Cria a estrutura a ser usada na View
	Local oModel   := FWLoadModel( 'TRETA004' )

	Local oView

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados será utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_MHZ', oStruMHZ, 'MHZMASTER' )

	// Criar um "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR', 100 )

	// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView( 'VIEW_MHZ', 'SUPERIOR' )

	// Liga a identificacao do componente
	oView:EnableTitleView('VIEW_MHZ','Dados do Tanque')

	// Define fechamento da tela
	oView:SetCloseOnOk( {||.T.} )

Return(oView)


/*/{Protheus.doc} TRETA4VA
Funcao para validar dados informado
- chamado na validacao de campo.

@author pablo
@since 09/10/2018
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function TRETA4VA(cCampo, xContent)

Local lRet			:= .T.

If cCampo == "MHZ_CAPNOM"

	if FwFldGet("MHZ_CAPMAX") > 0 .AND. xContent > 0 .AND. xContent > FwFldGet("MHZ_CAPMAX")
		Help(" ",1,"ATENÇÃO",,"Capacidade máxima não pode ser inferior a capacidade nominal.",3,1)
       	lRet:= .F.
	EndIf

Elseif cCampo == "MHZ_CAPMAX"

	If FwFldGet("MHZ_CAPMAX") > 0 .AND. xContent > 0 .AND. FwFldGet("MHZ_CAPNOM") > xContent
   		Help(" ",1,"ATENÇÃO",,"Capacidade máxima não pode ser inferior a capacidade nominal.",3,1)
       	lRet:= .F.
	EndIf

EndIf

Return lRet
