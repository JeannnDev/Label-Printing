/**-------------------------------------------------------------------------------------------**/
/** NOME DA FUNCAO: WsRestPost									            	              **/
/**-------------------------------------------------------------------------------------------**/
/**										CRIACAO / ALTERACOES / MANUTENCOES                    **/
/**-------------------------------------------------------------------------------------------**/
/** Data       	| Desenvolvedor          | Solicitacao         		| Descricao               **/
/**-------------------------------------------------------------------------------------------**/
/** 20/04/2026	| Jean Correa da Silva  | -                    	|  							  **/
/**-------------------------------------------------------------------------------------------**/
User Function WsRestPost(_cUrl, _cPath, _cBody, cIdRet)

    Local aArea      	:= GetArea()
    Local cResult    	:= ""
    Local cURL     		:= _cUrl
    Local cPath   	  := _cPath
    Local cBody       := _cBody
    Local aHeader     := {}
    Local oResult 		:= JsonObject():New()
    Local oRestClient := FWRest():New(cURL)
    Local oJson 			:= JsonObject():New()

    // Define o Path
    oRestClient:setPath(cPath)

    // adiciona os dados do header
    aAdd(aHeader, "User-Agent: Mozilla/4.0 (compatible; Protheus " + GetBuild() + ")")
    aAdd(aHeader, "Content-Type: application/json")
    aAdd(aHeader, "x-Language: pt-BR")

    // Set Parametros
    oRestClient:SetPostParams(EncodeUTF8(cBody))

    // faz a chamada do verbo
    If oRestClient:Post(aHeader, cBody)

        // obtem o retorno
        cResult := oRestClient:GetResult()

        // converte em objeto
        oResult:FromJson(cResult)

        If ValType(oResult['details']) == "J"

            If ValType(oResult['details']['output']) <> "U"

                cRetorno :=  oJson:FromJson(cValToChar(oResult['details']['output']))
                cIdRet 	 := cValToChar(oJson['result'])

            EndIf

        EndIf

    EndIf

    // restaura
    RestArea(aArea)

Return cResult