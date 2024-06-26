#include 'protheus.ch'
#INCLUDE "FWMVCDEF.CH"

/*/{Protheus.doc} TRETA040
Cadastro de Recados
@author TOTVS
@since 22/08/2019
@version P12
@param Nao recebe parametros
@return nulo
/*/

/***********************/
User Function TRETA040()
/***********************/
	
	Local oBrw := fwmBrowse():New()
	
	oBrw:SetDescription("Cadastro de Recados")
	oBrw:SetAlias("U92")
	//oBrw:SetFilterDefault("Empty(U92_FILREC) .Or. U92_FILREC == cFilAnt")
	oBrw:Activate()

Return

/*
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
����������������������������������������������������������������������������ͻ��
���Programa�MENUDEF      �Autor�Microsiga               ?Data ? 24/03/14   ��?
����������������������������������������������������������������������������͹��
���Desc.   �Opcoes do menu                                                   ��?
����������������������������������������������������������������������������͹��
���Param.  �Nao ha                                                           ��?
����������������������������������������������������������������������������͹��
���Retorno �Nao ha                                                           ��?
����������������������������������������������������������������������������͹��
���Uso     �Programa chamado pelo TRETA040                                   ��?
����������������������������������������������������������������������������ͼ��
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
*/
Static Function MenuDef()

	Local aBut	:= {}
	
	aAdd(aBut, {"Pesquisar"	, "PesqBrw"				, 0, 1, 0, NIL})
	aAdd(aBut, {"Visualizar", "VIEWDEF.TRETA040"	, 0, 2, 0, NIL})
	aAdd(aBut, {"Incluir"	, "VIEWDEF.TRETA040"	, 0, 3, 0, NIL})
	aAdd(aBut, {"Alterar"	, "VIEWDEF.TRETA040"	, 0, 4, 0, NIL})
	aAdd(aBut, {"Excluir"	, "VIEWDEF.TRETA040"	, 0, 5, 0, NIL})
	aAdd(aBut, {"Copiar"	, "VIEWDEF.TRETA040"	, 0, 9, 0, NIL})  
	
Return(aBut)

/*
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
����������������������������������������������������������������������������ͻ��
���Programa�MODELDEF     �Autor�Microsiga               ?Data ? 24/03/14   ��?
����������������������������������������������������������������������������͹��
���Desc.   �Modelo de dados                                                  ��?
����������������������������������������������������������������������������͹��
���Param.  �Nao ha                                                           ��?
����������������������������������������������������������������������������͹��
���Retorno �Nao ha                                                           ��?
����������������������������������������������������������������������������͹��
���Uso     �Programa chamado pelo UFATA011                                   ��?
����������������������������������������������������������������������������ͼ��
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
*/
Static Function ModelDef()
  
	Local oStrU92 := fwFormStruct(1, "U92")
	Local oModel
	
	// Cria a estrutura a ser usada no Modelo de Dados
	oModel	:= mpFormModel():New("TRETM040", /*bPreValidacao*/, /*bPosValidacao*/, /*bCommit*/, /*bCancel*/) 
	
	// Adiciona ao modelo uma estrutura de formul�rio de edi��o por campo
	oModel:AddFields("U92MASTER", /*cOwner*/, oStrU92)
	
	// Liga o controle de nao repeticao de linha
	oModel:SetPrimaryKey({"U92_FILIAL", "U92_CODIGO"})
	
	// Adiciona a descricao do Modelo de Dados
	oModel:SetDescription("Modelo de Dados de Recados")
	
Return(oModel)

/*
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
����������������������������������������������������������������������������ͻ��
���Programa�VIEWDEF      �Autor�Microsiga               ?Data ? 24/03/14   ��?
����������������������������������������������������������������������������͹��
���Desc.   �Tela                                                             ��?
����������������������������������������������������������������������������͹��
���Param.  �Nao ha                                                           ��?
����������������������������������������������������������������������������͹��
���Retorno �Nao ha                                                           ��?
����������������������������������������������������������������������������͹��
���Uso     �Programa chamado pelo TRETA040                                   ��?
����������������������������������������������������������������������������ͼ��
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
*/

Static Function ViewDef()
    
	Local oStrU92 := fwFormStruct(2, "U92")
	Local oModel
	Local oView
	
	// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
	oModel	:= fwLoadModel("TRETA040")
	
	// Cria o objeto de View
	oView	:= fwFormView():New()
	
	// Define qual o Modelo de dados ser?utilizado
	oView:SetModel(oModel)
	
	//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
	oView:AddField("VIEW_U92", oStrU92, "U92MASTER")
	
	// Criar "box" horizontal para receber algum elemento da view
	oView:CreateHorizontalBox("TELA", 100)
	
	// Relaciona o ID da View com o "box" para exibicao
	oView:SetOwnerView("VIEW_U92", "TELA")
	
	// Liga a identificacao do componente
	oView:EnableTitleView("VIEW_U92", "Recados")

Return(oView)   

/*
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
����������������������������������������������������������������������������ͻ��
���Programa� GetNomeCli  �Autor� Henrique Botelho         ?Data ? 25/03/2015 ��?
����������������������������������������������������������������������������͹��
���Desc.   � Fun��o que retorna o nome do cliente                            ��?
����������������������������������������������������������������������������͹��
���Param.  �Nao ha                                                           ��?
����������������������������������������������������������������������������͹��
���Retorno �Nao ha                                                           ��?
����������������������������������������������������������������������������͹��
���Uso     �Programa chamado pelo campo U92_NOMCLI                           ��?
����������������������������������������������������������������������������ͼ��
��������������������������������������������������������������������������������
��������������������������������������������������������������������������������
*/   

User Function GetNomeCli()   

Local cNome := ""

if AllTrim(FunName()) == "MATA030" .or. AllTrim(FunName()) == "CRMA980"   //se a fun��o foi chamada pelo MATA030(Cadastro de Clientes)
	cNome := SA1->A1_NREDUZ	
else
	if !INCLUI
		cNome := Posicione("SA1",1,xFilial("SA1") + U92->U92_CODCLI + U92->U92_LOJACL,"A1_NREDUZ")	
	endif 
endif

Return(cNome)
