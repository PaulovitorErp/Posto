#include "protheus.ch"  
#include "fwmvcdef.ch"

/*/{Protheus.doc} TRETA031
Cadastro Serviços Prestados por Fornecedor
@author TOTVS
@since 25/04/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/

/***********************/
User Function TRETA031()
/***********************/

Local oBrowse

oBrowse := FWmBrowse():New()
oBrowse:SetAlias("UH8")
oBrowse:SetDescription("Servicos Prestados por Fornecedor")
oBrowse:Activate()

Return Nil

/************************/
Static Function MenuDef()
/************************/

Local aRotina := {}

ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.TRETA031" OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE "Incluir"    ACTION "VIEWDEF.TRETA031" OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE "Alterar"    ACTION "VIEWDEF.TRETA031" OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE "Excluir"    ACTION "VIEWDEF.TRETA031" OPERATION 5 ACCESS 0
ADD OPTION aRotina TITLE "Imprimir"   ACTION "VIEWDEF.TRETA031" OPERATION 8 ACCESS 0
ADD OPTION aRotina TITLE "Copiar"     ACTION "VIEWDEF.TRETA031" OPERATION 9 ACCESS 0

Return aRotina

/*************************/
Static Function ModelDef()
/*************************/

// Cria a estrutura a ser usada no Modelo de Dados
Local oStruUH8 := FWFormStruct(1,"UH8",/*bAvalCampo*/,/*lViewUsado*/ )
Local oStruUH9 := FWFormStruct(1,"UH9",/*bAvalCampo*/,/*lViewUsado*/ )

Local oModel

// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New("TRETM031",/*bPreValidacao*/,/*bPosValidacao*/,/*bCommit*/,/*bCancel*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
oModel:AddFields("UH8MASTER",/*cOwner*/,oStruUH8)

// Adiciona a chave primaria da tabela principal
oModel:SetPrimaryKey({"UH8_FILIAL","UH8_FORNEC","UH8_LOJA"})

// Adiciona ao modelo uma estrutura de formulário de edição por grid
oModel:AddGrid("UH9DETAIL","UH8MASTER",oStruUH9,/*bLinePre*/,/*bLinePost*/,/*bPreVal*/,/*bPosVal*/,/*BLoad*/)

// Faz relaciomaneto entre os compomentes do model
oModel:SetRelation("UH9DETAIL", {{"UH9_FILIAL", 'xFilial("UH9")'},{"UH9_FORNEC","UH8_FORNEC"},{"UH9_LOJA","UH8_LOJA"}},UH9->(IndexKey(1)))

// Desobriga a digitacao de ao menos um item
//oModel:GetModel("UH9DETAIL"):SetOptional(.T.)

// Liga o controle de nao repeticao de linha
oModel:GetModel("UH9DETAIL"):SetUniqueLine({"UH9_PRODUT"})

// Adiciona a descricao do Modelo de Dados
oModel:SetDescription("Servicos Prestados por Fornecedor")

// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel("UH8MASTER"):SetDescription("Fornecedor")
oModel:GetModel("UH9DETAIL"):SetDescription("Servicos Prestados")

Return oModel

/************************/
Static Function ViewDef()
/************************/

// Cria a estrutura a ser usada na View
Local oStruUH8 := FWFormStruct(2,"UH8")
Local oStruUH9 := FWFormStruct(2,"UH9")

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel   := FWLoadModel("TRETA031")
Local oView

// Remove campos da estrutura
oStruUH9:RemoveField('UH9_FORNEC')
oStruUH9:RemoveField('UH9_LOJA')

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel( oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField("VIEW_UH8",oStruUH8,"UH8MASTER")

//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
oView:AddGrid("VIEW_UH9",oStruUH9,"UH9DETAIL")

// Criar "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox("EMCIMA" , 30)
oView:CreateHorizontalBox("EMBAIXO", 70)

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView("VIEW_UH8","EMCIMA")
oView:SetOwnerView("VIEW_UH9","EMBAIXO")

// Liga a identificacao do componente
oView:EnableTitleView("VIEW_UH8")
oView:EnableTitleView("VIEW_UH9","Serviços Prestados",RGB(224,30,43))

oView:SetCloseOnOk( {||.T.} )

Return oView