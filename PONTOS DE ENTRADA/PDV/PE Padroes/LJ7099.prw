#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} LJ7099
O Ponto de Entrada LJ7099, permite retornar uma string no formato XML com informa��es referentes a um Produto Especifico.
Somente informa��es do produto espec�fico devem ser retornados, ou seja, qualquer informa��o adicional pode causar inconsist�ncia do documento eletr�nico.

@author Anderson Machado
@since 29/12/2016
@version 1.0
@return cXML, Caracter, String no formato XML contendo as informa��es do produto espec�fico.
@type function
@obs
O Ponto de Entrada n�o recebe nenhum par�metro, por�m no momento da execu��o, o registro estar� posicionado no item em quest�o (SL2);
Como o registro est� posicionado no momento da execu��o do ponto de entrada, � IMPORTANTE que as fun��es GetArea e RestArea sejam utilizadas;
A string retornada n�o pode conter caracteres de quebra de linhas (exemplo: CRLF);
A informa��o do produto espec�fico deve ser retornada por item, ou seja, nesse caso o ponto de entrada ser� executado para cada item;
Somente um Produto Espec�fico pode ser informado por item;
Para saber quais informa��es devem ser retornadas, recomendamos a leitura das Normas T�cnicas em vigor;

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
