#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'FWMVCDEF.CH'

/*/{Protheus.doc} TRETA053

//Cadastro de Limite GRUPO Cliente por Segmento

@author danilo
@since 01/08/2023
@version 1.0
@return Nil

@type function
/*/
User function TRETA053()

	Local oBrowse

	Private aRotina
	Private cCadastro := 'Limites Grupo Cliente por Segmento'

	DbSelectArea("ACY")
	DbSelectArea("UC4")

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( 'ACY' )
	oBrowse:SetDescription( cCadastro )

	oBrowse:Activate()

Return

//-------------------------------------------------------------------
// Definicao do Menu
//-------------------------------------------------------------------
Static Function MenuDef()

	aRotina := {}

	ADD OPTION aRotina TITLE 'Visualizar'      ACTION 'VIEWDEF.TRETA053' OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE 'Limites'         ACTION 'VIEWDEF.TRETA053' OPERATION 4 ACCESS 0

Return aRotina

//-------------------------------------------------------------------
// Define Modelo de Dados
//-------------------------------------------------------------------
Static Function ModelDef()

	// Cria a estrutura a ser usada no Modelo de Dados
	Local oStruACY  := FWFormStruct( 1, 'ACY', {|cCampo| Alltrim(cCampo) $ "ACY_GRPVEN,ACY_DESCRI" },/*lViewUsado*/ )
	Local oStruUC4  := FWFormStruct( 1, 'UC4', /*bAvalCampo*/,/*lViewUsado*/ )
	Local oModel

	// Cria o objeto do Modelo de Dados
	oModel := MPFormModel():New('TRETM053', /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/ )

	// Adiciona ao modelo uma estrutura de formulario de edicao por campo
	oModel:AddFields( 'ACYMASTER', /*cOwner*/, oStruACY, /*bPreValidacao*/, /*bPosValidacao*/, /*bCarga*/ )

	// Adiciona a chave primaria da tabela principal
	oModel:SetPrimaryKey({ "ACY_FILIAL", "ACY_GRPVEN" })

	// Adiciona ao modelo uma componente de grid
	oModel:AddGrid( 'UC4DETAIL', 'ACYMASTER', oStruUC4 , /*bLinePre*/, /*bLinePost*/, /*bPreVal*/, /*bPosVal*/, /*BLoad*/ )

	// Faz relacionamento entre os componentes do model
	oModel:SetRelation( 'UC4DETAIL', { {'UC4_FILIAL', 'xFilial( "UC4" )'}, {'UC4_GRUPO', 'ACY_GRPVEN'} }, UC4->( IndexKey( 2 ) ) )

	// Liga o controle de nao repeticao de linha
	oModel:GetModel( 'UC4DETAIL' ):SetUniqueLine( { 'UC4_SEG' } )

	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription( 'Limites Grupo Cliente por Segmento' )

	// Adiciona a descrição dos Componentes do Modelo de Dados
	oModel:GetModel( 'UC4DETAIL' ):SetDescription( 'Limites Grupo Cliente por Segmento' )

	// tira obrigatoriedade de incluir linha
	oModel:GetModel( 'UC4DETAIL' ):SetOptional(.T.)

Return oModel

//-------------------------------------------------------------------
// Define camada de Visão
//-------------------------------------------------------------------
Static Function ViewDef()

	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	Local oModel   := FWLoadModel( 'TRETA053' )
	Local oView

	// Cria a estrutura a ser usada na View
	Local oStruACY := FWFormStruct( 2, 'ACY', {|cCampo| Alltrim(cCampo) $ "ACY_GRPVEN,ACY_DESCRI" },/*lViewUsado*/ )
	Local oStruUC4 := FWFormStruct( 2, 'UC4', /*bAvalCampo*/,/*lViewUsado*/ )

	//removo as pastas
	oStruACY:aFolders := {}

	// Remove campos da estrutura
	oStruUC4:RemoveField( 'UC4_CLIENT' )
	oStruUC4:RemoveField( 'UC4_LOJA' )
	oStruUC4:RemoveField( 'UC4_GRUPO' )

	// Cria o objeto de View
	oView := FWFormView():New()

	// Define qual o Modelo de dados ser· utilizado
	oView:SetModel( oModel )

	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField( 'VIEW_ACY', oStruACY, 'ACYMASTER' )

	//Adiciona no nosso View um controle do tipo Grid (antiga Getdados)
	oView:AddGrid( 'VIEW_UC4', oStruUC4, 'UC4DETAIL' )

	// Cria um "box" horizontal para receber cada elemento da view
	oView:CreateHorizontalBox( 'SUPERIOR'	, 20 )
	oView:CreateHorizontalBox( 'INFERIOR'	, 80 )

	// Relaciona o identificador (ID) da View com o "box" para exibição
	oView:SetOwnerView( 'VIEW_ACY', 'SUPERIOR' )
	oView:SetOwnerView( 'VIEW_UC4', 'INFERIOR' )

	// titulo dos componentes
	oView:EnableTitleView('VIEW_UC4' , /*'item'*/)

	//coloca cabeçalho apenas para visualizar.
	oView:SetOnlyView("ACYMASTER")

Return oView
