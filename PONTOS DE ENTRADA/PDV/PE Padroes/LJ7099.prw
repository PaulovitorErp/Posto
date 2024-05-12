#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ7099
O Ponto de Entrada LJ7099, permite retornar uma string no formato XML com informações referentes a um Produto Especifico.
Somente informações do produto específico devem ser retornados, ou seja, qualquer informação adicional pode causar inconsistência do documento eletrônico.

@author Anderson Machado
@since 29/12/2016
@version 1.0
@return cXML, Caracter, String no formato XML contendo as informações do produto específico.
@type function
@obs
O Ponto de Entrada não recebe nenhum parâmetro, porém no momento da execução, o registro estará posicionado no item em questão (SL2);
Como o registro está posicionado no momento da execução do ponto de entrada, é IMPORTANTE que as funções GetArea e RestArea sejam utilizadas;
A string retornada não pode conter caracteres de quebra de linhas (exemplo: CRLF);
A informação do produto específico deve ser retornada por item, ou seja, nesse caso o ponto de entrada será executado para cada item;
Somente um Produto Específico pode ser informado por item;
Para saber quais informações devem ser retornadas, recomendamos a leitura das Normas Técnicas em vigor;

/*/
User Function LJ7099()

	Local xRet

	///////////////////////////////////////////////////////////////////////////////////////////
	//             FUNCAO DO PACOTE POSTO INTELIGENTE - FAVOR NAO COMENTAR                  //
	/////////////////////////////////////////////////////////////////////////////////////////
	If ExistBlock("TPDVP003")
		 xRet := ExecBlock("TPDVP003",.F.,.F.)
	EndIf

Return xRet
