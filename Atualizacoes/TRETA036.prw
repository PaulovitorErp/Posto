#include 'protheus.ch'
#include 'fwmvcdef.ch'

/*/{Protheus.doc} TRETA036
Vale Serviço
@author TOTVS
@since 14/05/2019
@version P12
@param Nao recebe parametros
@return nulo
/*/

/***********************/
User Function TRETA036()
/***********************/
	
Local oBrowse

Private aRotina 	:= {}

oBrowse := FWmBrowse():New()
oBrowse:SetAlias("UIC")
oBrowse:SetDescription("Vale Serviço")   
oBrowse:Activate()

Return Nil

/************************/
Static Function MenuDef()
/************************/

aRotina 	:= {}

ADD OPTION aRotina Title 'Visualizar' 			Action "VIEWDEF.TRETA036"	OPERATION 2 ACCESS 0

Return aRotina

/*************************/
Static Function ModelDef()
/*************************/

// Cria a estrutura a ser usada no Modelo de Dados
Local oStruUIC := FWFormStruct(1,"UIC",/*bAvalCampo*/,/*lViewUsado*/ )

Local oModel

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New("TRETM036",/*bPreValidacao*/,/*bPosValidacao*/,/*bCommit*/,/*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
oModel:AddFields("UICMASTER",/*cOwner*/,oStruUIC)

// Adiciona a chave primaria da tabela principal
oModel:SetPrimaryKey({"UIC_FILIAL","UIC_CODIGO"})

// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel("UICMASTER"):SetDescription("Vale Serviço")

Return oModel

/************************/
Static Function ViewDef()
/************************/

// Cria a estrutura a ser usada na View
Local oStruUIC := FWFormStruct(2,"UIC")

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel   := FWLoadModel("TRETA036")
Local oView

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel(oModel)

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField("VIEW_UIC",oStruUIC,"UICMASTER")

// Criar "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox("PAINEL_CABEC", 100)

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView("VIEW_UIC","PAINEL_CABEC")

// Liga a identificacao do componente
oView:EnableTitleView("VIEW_UIC","Vale Serviço")

// Define fechamento da tela ao confirmar a operação
oView:SetCloseOnOk( {||.T.} )

Return oView